// Grants the Firestore/dashboard `admin` custom claim to a user by email.
//   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
//   node setAdmin.mjs you@example.com
import { readFile } from "node:fs/promises";
import { initializeApp, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const email = process.argv[2];
if (!email) throw new Error("usage: node setAdmin.mjs <email>");

initializeApp({
  credential: cert(JSON.parse(await readFile(process.env.GOOGLE_APPLICATION_CREDENTIALS, "utf8"))),
});

const user = await getAuth().getUserByEmail(email);
await getAuth().setCustomUserClaims(user.uid, { admin: true });
console.log(`admin claim set for ${email} (${user.uid}). Sign out/in on the dashboard.`);
process.exit(0);
