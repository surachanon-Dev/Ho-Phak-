// service ของการตั้งค่าแจ้งเตือน ค่าเริ่มต้น: messages=true, approvals=true, reviews=false
const notificationPrefModel = require('../models/notificationPrefModel');
const { fail } = require('../utils/AppError');

const DEFAULTS = { messages: true, approvals: true, reviews: false };

function toPrefs(row) {
    if (!row) return { ...DEFAULTS };
    return {
        messages: row.messages === 1,
        approvals: row.approvals === 1,
        reviews: row.reviews === 1,
    };
}

function toBool(value, label) {
    if (typeof value !== 'boolean') fail(400, `${label} ต้องเป็น true หรือ false`);
    return value;
}

async function get(userId) {
    return toPrefs(await notificationPrefModel.findByUser(userId));
}

async function update(userId, body) {
    const prefs = {
        messages: toBool(body.messages, 'messages'),
        approvals: toBool(body.approvals, 'approvals'),
        reviews: toBool(body.reviews, 'reviews'),
    };
    await notificationPrefModel.upsert(userId, {
        messages: prefs.messages ? 1 : 0,
        approvals: prefs.approvals ? 1 : 0,
        reviews: prefs.reviews ? 1 : 0,
    });
    return prefs;
}

module.exports = { get, update };
