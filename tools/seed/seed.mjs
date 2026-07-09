// One-time (re-runnable) seed: pushes the bundled scraped JSON + local images
// into Firestore + Cloud Storage, deduping images by content hash so the same
// photo used by many fighters/posters is stored once.
//
// Usage:
//   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
//   export STORAGE_BUCKET=walkout-xxxx.appspot.com
//   node seed.mjs
//
// The service-account key comes from Firebase console → Project settings →
// Service accounts → Generate new private key.

import { readFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, '../..');
const ASSETS = path.join(REPO, 'assets');

const bucketName = process.env.STORAGE_BUCKET;
if (!bucketName) throw new Error('Set STORAGE_BUCKET (e.g. walkout-xxxx.appspot.com)');

initializeApp({
  credential: cert(JSON.parse(await readFile(process.env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8'))),
  storageBucket: bucketName,
});
const db = getFirestore();
const bucket = getStorage().bucket();

const mediaCache = new Map(); // localPath -> public url

/** Upload a local asset once (by sha256) and return its public URL. */
async function uploadDeduped(assetPath, kind) {
  if (!assetPath) return '';
  if (mediaCache.has(assetPath)) return mediaCache.get(assetPath);
  const abs = path.join(REPO, assetPath);
  if (!existsSync(abs)) return ''; // asset missing → leave url empty
  const bytes = await readFile(abs);
  const hash = createHash('sha256').update(bytes).digest('hex');
  const ext = path.extname(assetPath) || '.webp';
  const objectPath = `media/${hash}${ext}`;
  const file = bucket.file(objectPath);
  const [exists] = await file.exists();
  if (!exists) {
    await file.save(bytes, { contentType: 'image/webp', resumable: false });
    await file.makePublic();
  }
  const url = `https://storage.googleapis.com/${bucketName}/${objectPath}`;
  await db.collection('media').doc(hash).set(
    { url, kind, path: objectPath, updatedAt: new Date() },
    { merge: true },
  );
  mediaCache.set(assetPath, url);
  return url;
}

async function loadJson(name) {
  return JSON.parse(await readFile(path.join(ASSETS, 'data', name), 'utf8'));
}

async function commitBatched(coll, docs, idOf) {
  let batch = db.batch();
  let n = 0;
  for (const d of docs) {
    batch.set(db.collection(coll).doc(idOf(d)), { ...d, updatedAt: new Date() }, { merge: true });
    if (++n % 400 === 0) { await batch.commit(); batch = db.batch(); }
  }
  await batch.commit();
  console.log(`seeded ${docs.length} → ${coll}`);
}

// SKIP_MEDIA=1 seeds data only and keeps the original asset paths (which the
// app renders from its bundle) — lets you seed before Storage/Blaze is on.
const skipMedia = !!process.env.SKIP_MEDIA;

// ── Fighters ──
const fighters = await loadJson('fighters.json');
for (const f of fighters) {
  const up = skipMedia ? '' : await uploadDeduped(f.imageUrl, 'fighter');
  f.imageUrl = up || f.imageUrl; // keep asset path if upload skipped/failed
  f.locked = f.locked ?? [];
}
await commitBatched('fighters', fighters, (f) => f.id);

// ── Events ──
const events = await loadJson('events.json');
for (const e of events) {
  const up = skipMedia ? '' : await uploadDeduped(e.heroImage, 'poster');
  e.heroImage = up || e.heroImage;
  e.locked = e.locked ?? [];
}
await commitBatched('events', events, (e) => e.id);

// ── Rankings (doc id = weightClass) ──
const rankings = await loadJson('rankings.json');
await commitBatched('rankings', rankings, (r) => r.weightClass);

await db.collection('meta').doc('ingest').set(
  { lastRunAt: new Date(), source: 'seed', errors: [] },
  { merge: true },
);

console.log(`done. media objects: ${mediaCache.size}`);
process.exit(0);
