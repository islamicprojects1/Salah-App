# Scripts

## backfill_family_member_ids.js

One-time migration to add `memberIds` to existing families. Required after deploying Firestore rules that use `memberIds` for access control.

**Prerequisites:**
```bash
npm init -y
npm install firebase-admin
```

**Set service account:**
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
```

**Run:**
```bash
node scripts/backfill_family_member_ids.js
```

After running, all families will have `memberIds` derived from `members[].userId`, and the full security rules will apply.
