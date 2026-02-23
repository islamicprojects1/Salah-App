/**
 * Salah App — Express Backend
 *
 * بديل كامل لـ Cloud Functions:
 * - يستمع لتغييرات Firestore (groups/{groupId}/members، encouragements)
 * - يرسل إشعارات FCM للعائلة (Topic: family_{groupId})
 *
 * الدراسة: docs/FAMILY_FEATURE_STUDY.md
 */

require('dotenv').config();

const express = require('express');
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(express.json());

// تهيئة Firebase Admin
let db = null;
let messaging = null;

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (credentialsPath) {
  const keyPath = path.resolve(process.cwd(), credentialsPath);
  if (!fs.existsSync(keyPath)) {
    console.warn('[Firebase] Service account file not found:', keyPath);
    console.warn('[Firebase] 1) Copy .env.example to .env');
    console.warn('[Firebase] 2) Download JSON key from Firebase Console → Project Settings → Service accounts → Generate new key');
    console.warn('[Firebase] 3) Save it in backend/ as serviceAccountKey.json and set GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json in .env');
  } else {
    try {
      const serviceAccount = require(keyPath);
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      db = admin.firestore();
      messaging = admin.messaging();
      console.log('[Firebase] ✓ Admin SDK initialized.');
    } catch (e) {
      console.warn('[Firebase] Failed to load service account:', e.message);
    }
  }
} else {
  console.warn('[Firebase] GOOGLE_APPLICATION_CREDENTIALS not set. Copy .env.example to .env and add the path to your service account JSON.');
}

/**
 * إرسال إشعار إلى Topic العائلة
 */
async function sendToFamilyTopic(groupId, titleAr, bodyAr, data = {}) {
  if (!messaging) return;
  const topic = `family_${groupId}`;
  await messaging.send({
    topic,
    notification: { title: titleAr, body: bodyAr, sound: 'default' },
    data: { type: 'family_activity', groupId, ...data },
    android: { priority: 'high' },
  });
  console.log(`[FCM] Sent to ${topic}: ${titleAr}`);
}

/**
 * مراقبة Firestore — groups و members و encouragements
 */
function attachFirestoreListeners() {
  if (!db) {
    console.log('[Firestore] Skipped (no Admin SDK).');
    return;
  }

  // مراقبة encouragements (إن وُجدت المجموعة في المشروع)
  try {
    db.collectionGroup('encouragements').onSnapshot(
      (snap) => {
        console.log('[Firestore] Encouragements loaded:', snap.size, 'docs.');
      },
      (err) => console.warn('[Firestore] Encouragements listener:', err.message)
    );
  } catch (_) {}

  // مراقبة members عبر collectionGroup
  try {
    db.collectionGroup('members').onSnapshot(
      (snap) => {
        console.log('[Firestore] Members loaded:', snap.size, 'docs.');
      },
      (err) => console.warn('[Firestore] Members listener:', err.message)
    );
  } catch (_) {}

  console.log('[Firestore] All listeners attached.');
}

// Health check
app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'salah-backend' });
});

// إشعار: يصلّي الآن
app.post('/api/notify/praying-now', async (req, res) => {
  const { groupId, memberName, prayerName } = req.body || {};
  if (!groupId || !memberName || !prayerName) {
    return res.status(400).json({ error: 'Missing groupId, memberName, or prayerName' });
  }
  try {
    await sendToFamilyTopic(
      groupId,
      `${memberName} يصلّي ${prayerName} الآن 🤲`,
      'اللهم تقبل',
      { event: 'praying_now', memberName, prayerName }
    );
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

// إشعار: أكمل صلاة
app.post('/api/notify/prayer-completed', async (req, res) => {
  const { groupId, memberName, prayerName } = req.body || {};
  if (!groupId || !memberName || !prayerName) {
    return res.status(400).json({ error: 'Missing groupId, memberName, or prayerName' });
  }
  try {
    await sendToFamilyTopic(
      groupId,
      `${memberName} أكملت/أكمل ${prayerName} 🌟`,
      'ما شاء الله',
      { event: 'prayer_completed', memberName, prayerName }
    );
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('[Server] Salah backend running on port', PORT);
  attachFirestoreListeners();
});
