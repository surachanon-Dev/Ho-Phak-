// model ของตาราง admin_logs (บันทึกการกระทำของ admin)
const db = require('../config/db');

async function insert(admin, action, targetType, targetId, details, conn = db) {
    await conn.query(
        'INSERT INTO admin_logs (admin_id, admin_name, action, target_type, target_id, details) VALUES (?, ?, ?, ?, ?, ?)',
        [admin.id, admin.username, action, targetType, targetId, details ? JSON.stringify(details) : null]);
}

async function listRecent() {
    const [rows] = await db.query('SELECT * FROM admin_logs ORDER BY id DESC LIMIT 100');
    return rows;
}

// log ล่าสุดของ action หนึ่งบนเป้าหมายหนึ่ง (details แปลงเป็น object แล้ว หรือ null)
async function findLatest(action, targetType, targetId, conn = db) {
    const [rows] = await conn.query(
        'SELECT details FROM admin_logs WHERE action = ? AND target_type = ? AND target_id = ? ORDER BY id DESC LIMIT 1',
        [action, targetType, targetId]);
    if (!rows[0]) return null;
    const { details } = rows[0];
    if (details === null || details === undefined) return {};
    if (typeof details !== 'string') return details;
    try {
        return JSON.parse(details);
    } catch {
        return {};
    }
}

module.exports = { insert, listRecent, findLatest };
