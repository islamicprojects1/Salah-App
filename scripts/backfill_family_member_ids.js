/**
 * One-time migration: backfill memberIds for families that only have members[].
 *
 * Run: node scripts/backfill_family_member_ids.js
 *
 * Requires: npm install firebase-admin
 * Set GOOGLE_APPLICATION_CREDENTIALS to the full path of your service account JSON.
 * Example (PowerShell): $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\You\Downloads\salah-app-service-account.json"
 */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

async function main() {
  if (!admin.apps.length) {
    const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (!credPath) {
      console.error('Set GOOGLE_APPLICATION_CREDENTIALS to the path of your service account JSON file.');
      console.error('Example: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\Users\\You\\Downloads\\salah-app-service-account.json"');
      process.exit(1);
    }
    const absPath = path.isAbsolute(credPath) ? credPath : path.resolve(process.cwd(), credPath);
    if (!fs.existsSync(absPath)) {
      console.error('File not found:', absPath);
      console.error('Make sure the path is correct and the file exists.');
      process.exit(1);
    }
    const serviceAccount = JSON.parse(fs.readFileSync(absPath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount), projectId: serviceAccount.project_id });
  }
  const db = admin.firestore();

  const snapshot = await db.collection('families').get();
  let updated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const memberIds = data.memberIds || [];
    if (memberIds.length > 0) continue; // already has memberIds

    const members = data.members || [];
    const ids = members
      .map((m) => (m && m.userId) || null)
      .filter(Boolean);
    if (ids.length === 0) continue;

    await doc.ref.update({ memberIds: ids });
    updated++;
    console.log(`Updated ${doc.id}: ${ids.join(', ')}`);
  }

  console.log(`Done. Updated ${updated} families.`);
}

main().catch(console.error);
