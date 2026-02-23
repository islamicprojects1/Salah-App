/**
 * fcm.js — إرسال إشعارات FCM
 * sendToTopic  → Topic العائلة (كل أفراد المجموعة)
 * sendToToken  → مستخدم بعينه (مدير، مستهدف دعاء، إلخ)
 */

const admin = require('firebase-admin');

/**
 * إرسال إشعار إلى Topic عائلة (family_{groupId})
 * @param {string} topic
 * @param {string} title
 * @param {string} body
 * @param {Record<string,string>} data  — payload إضافي (قيم strings فقط)
 */
async function sendToTopic(topic, title, body, data = {}) {
  try {
    const messaging = admin.messaging();
    // FCM يشترط أن تكون قيم data كلها strings
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v ?? '')])
    );

    await messaging.send({
      topic,
      notification: { title, body },
      data: stringData,
      android: {
        priority: 'high',
        notification: { sound: 'default', channelId: 'family_activity' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });

    console.log(`[FCM] ✓ topic:${topic} | ${title}`);
  } catch (err) {
    // INVALID_ARGUMENT: topic doesn't exist yet (لا أعضاء مشتركين) → طبيعي
    if (err.code === 'messaging/invalid-argument') {
      console.warn(`[FCM] Topic ${topic} has no subscribers yet.`);
    } else {
      console.error(`[FCM] ✗ topic:${topic} |`, err.message);
    }
  }
}

/**
 * إرسال إشعار إلى مستخدم واحد عبر FCM Token
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {Record<string,string>} data
 */
async function sendToToken(token, title, body, data = {}) {
  if (!token) {
    console.warn('[FCM] sendToToken: token is empty, skipping.');
    return;
  }

  try {
    const stringData = Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v ?? '')])
    );

    await admin.messaging().send({
      token,
      notification: { title, body },
      data: stringData,
      android: {
        priority: 'high',
        notification: { sound: 'default', channelId: 'family_activity' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });

    console.log(`[FCM] ✓ token:${token.slice(0, 12)}... | ${title}`);
  } catch (err) {
    // Token منتهي الصلاحية → طبيعي (المستخدم أعاد تثبيت التطبيق)
    if (err.code === 'messaging/registration-token-not-registered') {
      console.warn(`[FCM] Token ${token.slice(0, 12)}... is no longer valid.`);
    } else {
      console.error(`[FCM] ✗ token:${token.slice(0, 12)}... |`, err.message);
    }
  }
}

module.exports = { sendToTopic, sendToToken };
