/**
 * helpers.js — بناء نصوص الإشعارات + فلترة Ghost Mode
 */

// أسماء الصلوات بالعربية
const PRAYER_NAMES_AR = {
  fajr:    'الفجر',
  dhuhr:   'الظهر',
  asr:     'العصر',
  maghrib: 'المغرب',
  isha:    'العشاء',
};

const PRAYER_NAMES_EN = {
  fajr:    'Fajr',
  dhuhr:   'Dhuhr',
  asr:     'Asr',
  maghrib: 'Maghrib',
  isha:    'Isha',
};

/**
 * اسم الصلاة بالعربية
 * @param {string} name
 */
function prayerAr(name) {
  return PRAYER_NAMES_AR[(name || '').toLowerCase()] || name || '';
}

/**
 * اسم الصلاة بالإنجليزية
 * @param {string} name
 */
function prayerEn(name) {
  return PRAYER_NAMES_EN[(name || '').toLowerCase()] || name || '';
}

/**
 * تحويل Firestore Timestamp أو أي تمثيل للوقت إلى milliseconds
 * @param {any} value
 * @returns {number|null}
 */
function toMs(value) {
  if (!value) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value.seconds)  return value.seconds  * 1000;
  if (value._seconds) return value._seconds * 1000;
  if (value instanceof Date) return value.getTime();
  const parsed = new Date(value).getTime();
  return isNaN(parsed) ? null : parsed;
}

/**
 * تحقق من وضع التخفي (Ghost Mode) لمستخدم معين
 * إذا فعّله → لا يُرسَل عنه أي إشعار للعائلة
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @returns {Promise<boolean>}
 */
async function isGhostMode(db, userId) {
  if (!userId || !db) return false;
  try {
    const doc = await db.collection('users').doc(userId).get();
    return doc.exists && doc.data().familyGhostMode === true;
  } catch {
    return false;
  }
}

/**
 * جلب FCM token لمستخدم
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @returns {Promise<string|null>}
 */
async function getFcmToken(db, userId) {
  if (!userId || !db) return null;
  try {
    const doc = await db.collection('users').doc(userId).get();
    return doc.exists ? (doc.data().fcmToken || null) : null;
  } catch {
    return null;
  }
}

/**
 * جلب adminId لمجموعة
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} groupId
 * @returns {Promise<string|null>}
 */
async function getGroupAdminId(db, groupId) {
  if (!groupId || !db) return null;
  try {
    const doc = await db.collection('groups').doc(groupId).get();
    return doc.exists ? (doc.data().adminId || null) : null;
  } catch {
    return null;
  }
}

module.exports = { prayerAr, prayerEn, toMs, isGhostMode, getFcmToken, getGroupAdminId };
