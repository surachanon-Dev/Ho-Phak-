// model ของตาราง favorites
const db = require('../config/db');

async function listByUser(userId) {
    const [rows] = await db.query(
        `SELECT d.id, d.name, d.zone, d.price_per_month, d.status, f.created_at AS saved_at
         FROM favorites f JOIN dormitories d ON d.id = f.dormitory_id
         WHERE f.user_id = ? ORDER BY f.created_at DESC`, [userId]);
    return rows;
}

async function insertIgnore(userId, dormitoryId) {
    await db.query('INSERT IGNORE INTO favorites (user_id, dormitory_id) VALUES (?, ?)', [userId, dormitoryId]);
}

async function remove(userId, dormitoryId) {
    const [result] = await db.query('DELETE FROM favorites WHERE user_id = ? AND dormitory_id = ?', [userId, dormitoryId]);
    return result.affectedRows;
}

module.exports = { listByUser, insertIgnore, remove };
