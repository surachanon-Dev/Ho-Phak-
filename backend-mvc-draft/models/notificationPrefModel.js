// model ของตาราง notification_preferences (การตั้งค่าแจ้งเตือนรายบุคคล)
const db = require('../config/db');

async function findByUser(userId) {
    const [rows] = await db.query(
        'SELECT messages, approvals, reviews FROM notification_preferences WHERE user_id = ?', [userId]);
    return rows[0];
}

async function upsert(userId, { messages, approvals, reviews }) {
    await db.query(
        `INSERT INTO notification_preferences (user_id, messages, approvals, reviews) VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE messages = VALUES(messages), approvals = VALUES(approvals), reviews = VALUES(reviews)`,
        [userId, messages, approvals, reviews]);
}

module.exports = { findByUser, upsert };
