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

module.exports = { insert, listRecent };
