// model ของตาราง notifications
const db = require('../config/db');

async function listByUser(userId) {
    const [rows] = await db.query(
        `SELECT id, type, title, body, related_type, related_id, read_at, created_at
         FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 50`, [userId]);
    return rows;
}

async function findOwned(id, userId) {
    const [rows] = await db.query('SELECT id FROM notifications WHERE id = ? AND user_id = ?', [id, userId]);
    return rows[0];
}

async function markRead(id) {
    await db.query('UPDATE notifications SET read_at = COALESCE(read_at, NOW()) WHERE id = ?', [id]);
}

async function insert(userId, { type, title, body = null, relatedType = null, relatedId = null }, conn = db) {
    await conn.query(
        'INSERT INTO notifications (user_id, type, title, body, related_type, related_id) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, type, title, body, relatedType, relatedId]);
}

module.exports = { listByUser, findOwned, markRead, insert };
