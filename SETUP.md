# Walkout — Firebase backend setup

## FREE path (no Blaze) — what's actually wired for walkout-69
Done: Firestore (rules+indexes+data seeded), Auth (Google), Hosting
(dashboard live at https://walkout-69.web.app), admin claim.

Ingest runs on **GitHub Actions** (free) instead of Cloud Functions — no
billing. `tools/ingest/ingest.py` scrapes → writes Firestore → sends the FCM
push itself. To activate:
1. Push this repo to GitHub.
2. Repo → Settings → Secrets and variables → Actions → New secret
   `FIREBASE_SA` = the full contents of `tools/seed/sa.json`.
3. Actions tab → "Walkout ingest" → Run workflow (or wait for the 30-min cron).
4. Tune the `TODO` selectors in `ingest.py` against live ufc.com pages
   (`python tools/ingest/ingest.py --dry-run --limit 10` locally to test).

Cloud Storage + `functions/` (below) are only if you later upgrade to Blaze
and want in-house image mirroring + minute-level scheduling. Not required.

---


All the code is in the repo. These are the credential-gated steps only **you** can
run (they need your Google login). Run them in order.

## What's where
- `lib/` — app reads Firestore when `AppConstants.firebaseEnabled = true`, else bundled JSON.
- `firestore.rules` / `storage.rules` / `firestore.indexes.json` — security + indexes.
- `functions/` — `scheduledIngest` (pulls data every min, adaptive) + `onDataChanged` (push → phones).
- `tools/seed/` — one-time upload of bundled JSON + images (sha256-deduped); `setAdmin.mjs`.
- `dashboard/` — Next.js admin console (monitor / edit+lock / media / publish).

## 0. Prereqs
```
npm i -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

## 1. Wire the Flutter app to your project
```
flutterfire configure     # pick the "Walkout" project, enable Android + iOS
```
Then set the project id in `.firebaserc` (replace REPLACE_WITH_YOUR_PROJECT_ID),
or run `firebase use --add` and pick Walkout.
Flip the switch: in `lib/core/constants/app_constants.dart` set
`firebaseEnabled = true`.

## 2. Enable services (Firebase console)
- **Firestore** → Create database (production mode).
- **Storage** → Get started.
- **Authentication** → enable **Google** provider.
- **Upgrade to Blaze** (pay-as-you-go) — required for Functions + Scheduler. Costs pennies at this scale.

## 3. Deploy rules
```
firebase deploy --only firestore:rules,storage,firestore:indexes
```

## 4. Seed data (bundled JSON + images → Firestore/Storage, deduped)
Firebase console → Project settings → Service accounts → **Generate new private key** → save as `sa.json`.
```
cd tools/seed && npm install
export GOOGLE_APPLICATION_CREDENTIALS=/abs/path/sa.json
export STORAGE_BUCKET=<your-bucket>        # e.g. walkout-xxxx.appspot.com
npm run seed
```

## 5. Make yourself a dashboard admin
```
node setAdmin.mjs you@gmail.com            # same folder, same GOOGLE_APPLICATION_CREDENTIALS
```

## 6. Functions (ingest + push)
Point the ingest at your Scrapling output (HTTP endpoint or published JSON):
```
cd ../../functions && npm install
firebase functions:config:set  # (or set SCRAPER_URL env in the function)
firebase deploy --only functions
```
`SCRAPER_URL` should serve `/fighters.json`, `/events.json`, `/rankings.json`
(the normalized shape of `assets/data/*.json`). Direct UFC endpoints can be
added later in `functions/src/sources.ts`.

## 7. Dashboard
```
cd ../dashboard
cp .env.local.example .env.local           # fill from console → Web app config
npm install
npm run dev                                 # local, or:
npm run build && firebase deploy --only hosting
```

## 8. Verify the loop
1. Dashboard → edit a fighter's record → **lock** it → Save → **Publish → phones**.
2. Phone: the fighter/widget updates (open app, or wait for the push to refresh widgets).
3. Next ingest run must NOT overwrite the locked field.

## Notes
- Sub-minute live updates need a self-looping Cloud Run job; the scheduled
  function floors at 1 min. Fine for everything except live in-fight seconds.
- Widget photos render from downloaded copies; first paint after a new photo
  may lag one refresh while it caches.
