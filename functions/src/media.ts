import { createHash } from "crypto";
import { getStorage } from "firebase-admin/storage";
import { getFirestore } from "firebase-admin/firestore";

/**
 * Uploads image bytes once, keyed by sha256, and returns a public URL. A photo
 * shared by many fighters/posters is stored a single time. Returns "" on any
 * failure so ingest never crashes on a bad image.
 */
export async function uploadDeduped(
  bytes: Buffer,
  kind: "fighter" | "poster",
  ext = ".webp"
): Promise<string> {
  try {
    const hash = createHash("sha256").update(bytes).digest("hex");
    const objectPath = `media/${hash}${ext}`;
    const bucket = getStorage().bucket();
    const file = bucket.file(objectPath);
    const [exists] = await file.exists();
    if (!exists) {
      await file.save(bytes, { contentType: "image/webp", resumable: false });
      await file.makePublic();
    }
    const url = `https://storage.googleapis.com/${bucket.name}/${objectPath}`;
    await getFirestore()
      .collection("media")
      .doc(hash)
      .set({ url, kind, path: objectPath, updatedAt: new Date() }, { merge: true });
    return url;
  } catch {
    return "";
  }
}

/** Fetches a remote image and dedups it into Storage. */
export async function mirrorImage(
  srcUrl: string,
  kind: "fighter" | "poster"
): Promise<string> {
  if (!srcUrl) return "";
  try {
    const res = await fetch(srcUrl);
    if (!res.ok) return "";
    const buf = Buffer.from(await res.arrayBuffer());
    return uploadDeduped(buf, kind);
  } catch {
    return "";
  }
}
