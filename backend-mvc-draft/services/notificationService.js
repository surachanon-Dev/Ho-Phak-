// service ของการแจ้งเตือนของผู้ใช้
const notificationModel = require('../models/notificationModel');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

async function list(userId) {
    return notificationModel.listByUser(userId);
}

async function markRead(rawId, userId) {
    const id = toInt(rawId);
    const row = id === null ? undefined : await notificationModel.findOwned(id, userId);
    if (!row) fail(404, 'ไม่พบการแจ้งเตือน');
    await notificationModel.markRead(id);
}

module.exports = { list, markRead };
