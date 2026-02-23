/**
 * firestore.js — Firestore Listeners + Cleanup
 *
 * يستمع لـ:
 *   1. collectionGroup('members')      → prayingNow, todayPrayers, عضو جديد
 *   2. collectionGroup('encouragements') → دعاء "اللهم تقبل" + تشجيع
 *
 * ويُنظّف: prayingNow القديمة (أكثر من 20 دقيقة)
 */

const { sendToTopic, sendToToken } = require('./fcm');
const { prayerAr, toMs, isGhostMode, getFcmToken, getGroupAdminId } = require('./helpers');

// ────────────────────────────────────────────────────────────────
// في الذاكرة: حالة كل عضو (docPath → state)
// ────────────────────────────────────────────────────────────────
const memberStates = new Map();

/**
 * بناء حالة العضو المُخزَّنة في الذاكرة
 * @param {object} data — Firestore document data
 * @returns {{prayingNow, todayPrayers, todayPrayersDate}}
 */
function buildState(data) {
  const today = todayKey();
  return {
    prayingNow:       data.prayingNow       || null,
    todayPrayers:     data.todayPrayersDate === today ? (data.todayPrayers || []) : [],
    todayPrayersDate: data.todayPrayersDate || null,
  };
}

/** "2026-02-23" */
function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

// ────────────────────────────────────────────────────────────────
// Deduplication: تجنب إرسال نفس الإشعار مرتين في فترة قصيرة
// ────────────────────────────────────────────────────────────────
const recentlySent = new Map(); // key → timestamp

function isDuplicate(key, ttlMs = 60_000) {
  const last = recentlySent.get(key);
  if (last && Date.now() - last < ttlMs) return true;
  recentlySent.set(key, Date.now());
  // تنظيف دوري للذاكرة كل 1000 إدخال
  if (recentlySent.size > 1000) {
    const cutoff = Date.now() - 600_000; // 10 دقائق
    for (const [k, v] of recentlySent) {
      if (v < cutoff) recentlySent.delete(k);
    }
  }
  return false;
}

// ────────────────────────────────────────────────────────────────
// MAIN: ربط كل الـ Listeners
// ────────────────────────────────────────────────────────────────

/**
 * @param {FirebaseFirestore.Firestore} db
 */
function attachListeners(db) {
  if (!db) {
    console.warn('[Firestore] db not available. Listeners not attached.');
    return;
  }

  attachMembersListener(db);
    attachEncouragementsListener(db);

  console.log('[Firestore] All listeners attached.');
}

// ────────────────────────────────────────────────────────────────
// 1. Listener: members
// ────────────────────────────────────────────────────────────────

function attachMembersListener(db) {
  let initialized = false;

  db.collectionGroup('members').onSnapshot(
    (snapshot) => {
      if (!initialized) {
        // التحميل الأولي: نبني الخريطة فقط، لا إشعارات
        initialized = true;
        snapshot.docs.forEach((doc) => {
          memberStates.set(doc.ref.path, buildState(doc.data()));
        });
        console.log(`[Firestore] Members loaded: ${snapshot.size} docs.`);
        return;
      }

      // تغييرات حقيقية بعد التحميل
      snapshot.docChanges().forEach((change) => {
        const doc    = change.doc;
        const data   = doc.data();
        const path   = doc.ref.path;
        const groupId = doc.ref.parent.parent?.id;
        if (!groupId) return;

        if (change.type === 'added') {
          // عضو جديد انضم
          memberStates.set(path, buildState(data));
          handleNewMember(db, groupId, data).catch(console.error);

        } else if (change.type === 'modified') {
          const prev = memberStates.get(path) || {};
          handleMemberUpdate(db, groupId, data, prev).catch(console.error);
          memberStates.set(path, buildState(data));

        } else if (change.type === 'removed') {
          memberStates.delete(path);
        }
      });
    },
    (err) => {
      initialized = false; // إعادة التهيئة عند الخطأ
      console.error('[Firestore] Members listener error:', err.message);
    }
  );
}

// ────────────────────────────────────────────────────────────────
// 2. Listener: encouragements (دعاء + تشجيع)
// ────────────────────────────────────────────────────────────────

function attachEncouragementsListener(db) {
  let initialized   = false;
  const seen = new Set();

  db.collectionGroup('encouragements').onSnapshot(
    (snapshot) => {
      if (!initialized) {
        initialized = true;
        snapshot.docs.forEach((doc) => seen.add(doc.id));
        console.log(`[Firestore] Encouragements loaded: ${snapshot.size} docs.`);
        return;
      }

      snapshot.docChanges().forEach((change) => {
        if (change.type !== 'added') return;
        if (seen.has(change.doc.id))  return;
        seen.add(change.doc.id);
        handleEncouragement(db, change.doc.data()).catch(console.error);
      });
    },
    (err) => {
      console.error('[Firestore] Encouragements listener error:', err.message);
    }
  );
}

// ────────────────────────────────────────────────────────────────
// Handlers
// ────────────────────────────────────────────────────────────────

/** عضو جديد انضم → إشعار للمدير */
async function handleNewMember(db, groupId, data) {
  if (!data.isActive || data.isShadow) return; // الظل لا يحتاج إشعار انضمام

  const key = `new_member:${groupId}:${data.userId}`;
  if (isDuplicate(key, 30_000)) return;

  const adminId  = await getGroupAdminId(db, groupId);
  if (!adminId || adminId === data.userId) return; // المدير هو نفسه المنضم

  const fcmToken = await getFcmToken(db, adminId);
  if (!fcmToken) return;

  const name = data.displayName || 'مستخدم جديد';
  await sendToToken(
    fcmToken,
    `${name} انضم لعائلتك 👋`,
    'افتح التطبيق لترحيب به',
    { type: 'new_member', groupId, memberId: data.userId || '' }
  );
}

/** تحديث بيانات عضو → كشف تغيير prayingNow أو todayPrayers */
async function handleMemberUpdate(db, groupId, data, prev) {
  const userId = data.userId || '';

  // ── prayingNow ──────────────────────────────────────────────
  const newPN = data.prayingNow || null;
  const prevPN = prev.prayingNow || null;

  // prayingNow أُضيف أو تغيّر اسم الصلاة
  if (newPN && newPN.prayerName !== prevPN?.prayerName) {
    await handlePrayingNow(db, groupId, data, newPN);
  }

  // ── todayPrayers ────────────────────────────────────────────
  const today      = todayKey();
  const newDate    = data.todayPrayersDate || null;
  const newPrayers = newDate === today ? (data.todayPrayers || []) : [];
  const prevPrayers = prev.todayPrayers || [];

  if (newDate === today && newPrayers.length > prevPrayers.length) {
    // الصلوات الجديدة
    const added = newPrayers.filter((p) => !prevPrayers.includes(p));
    // fallback: آخر عناصر المصفوفة إن فشل filter
    const toNotify = added.length > 0 ? added : newPrayers.slice(prevPrayers.length);

    for (const prayerName of toNotify) {
      await handlePrayerCompleted(db, groupId, data, prayerName);
    }
  }
}

/** يصلّي الآن → FCM للعائلة */
async function handlePrayingNow(db, groupId, data, prayingNow) {
  const userId = data.userId || '';
  const key    = `praying_now:${groupId}:${userId}:${prayingNow.prayerName}`;
  if (isDuplicate(key, 90_000)) return; // dedup 90 ثانية

  if (await isGhostMode(db, userId)) return;

  const name   = data.displayName || 'أحد أفراد العائلة';
  const prayer = prayerAr(prayingNow.prayerName);

  await sendToTopic(
    `family_${groupId}`,
    `${name} يصلّي ${prayer} الآن 🤲`,
    'اللهم تقبل',
    { type: 'praying_now', groupId, userId, prayerName: prayingNow.prayerName }
  );
}

/** أكمل صلاة → FCM للعائلة */
async function handlePrayerCompleted(db, groupId, data, prayerName) {
  const userId = data.userId || '';
  const today  = todayKey();
  const key    = `prayer_done:${groupId}:${userId}:${prayerName}:${today}`;
  if (isDuplicate(key, 300_000)) return; // dedup 5 دقائق

  if (await isGhostMode(db, userId)) return;

  const name   = data.displayName || 'أحد أفراد العائلة';
  const prayer = prayerAr(prayerName);

  await sendToTopic(
    `family_${groupId}`,
    `${name} أكمل ${prayer} ✨`,
    'ما شاء الله — اللهم تقبل',
    { type: 'prayer_completed', groupId, userId, prayerName }
  );
}

/** دعاء "اللهم تقبل" أو تشجيع → إشعار للمستهدف */
async function handleEncouragement(db, data) {
  const { type, to: targetId, from: fromName, groupId } = data;
  if (!targetId || !fromName) return;

  const key = `encouragement:${targetId}:${fromName}:${Date.now()}`;
  if (isDuplicate(key, 5_000)) return;

  const fcmToken = await getFcmToken(db, targetId);
  if (!fcmToken) return;

  const isDua   = type === 'dua';
  const title   = isDua ? `${fromName} دعا لك 🤲` : `${fromName} يشجّعك على الصلاة 💪`;
  const body    = isDua ? 'اللهم تقبل صلاتك'       : 'لا تفوّت هذه الصلاة مع عائلتك';

  await sendToToken(
    fcmToken,
    title,
    body,
    { type: type || 'encouragement', groupId: groupId || '', fromName }
  );
}

// ────────────────────────────────────────────────────────────────
// Cleanup: مسح prayingNow القديمة (أكثر من 20 دقيقة)
// يُشغَّل من index.js كل ساعة
// ────────────────────────────────────────────────────────────────

/**
 * @param {FirebaseFirestore.Firestore} db
 */
async function cleanupStalePrayingNow(db) {
  if (!db) return;

  const TWENTY_MIN_MS = 20 * 60 * 1000;
  const cutoff = Date.now() - TWENTY_MIN_MS;
  let   count  = 0;

  // نعتمد على الخريطة في الذاكرة — لا نحتاج Firestore query
  for (const [path, state] of memberStates.entries()) {
    if (!state.prayingNow) continue;

    const startMs = toMs(state.prayingNow.startedAt);
    if (startMs === null || startMs > cutoff) continue;

    try {
      await db.doc(path).update({ prayingNow: null });
      memberStates.set(path, { ...state, prayingNow: null });
      count++;
      console.log(`[Cleanup] Cleared prayingNow for ${path}`);
    } catch (err) {
      console.error(`[Cleanup] Error clearing ${path}:`, err.message);
    }
  }

  if (count > 0) {
    console.log(`[Cleanup] Done. Cleared ${count} stale prayingNow entries.`);
  }
}

module.exports = { attachListeners, cleanupStalePrayingNow };
