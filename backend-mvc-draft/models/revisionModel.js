// model ของตาราง dormitory_revisions (ฉบับแก้ไขที่รอ admin ตรวจ)
const db = require('../config/db');

async function findPending(dormitoryId, conn = db, forUpdate = false) {
    const lock = forUpdate ? ' FOR UPDATE' : '';
    const [rows] = await conn.query(
        `SELECT * FROM dormitory_revisions WHERE dormitory_id = ? AND status = 'pending'
         ORDER BY id DESC LIMIT 1${lock}`, [dormitoryId]);
    return rows[0];
}

async function findLatest(dormitoryId) {
    const [rows] = await db.query(
        `SELECT id, payload, status, rejection_reason, submitted_at FROM dormitory_revisions
         WHERE dormitory_id = ? ORDER BY id DESC LIMIT 1`, [dormitoryId]);
    return rows[0];
}

async function insert(dormitoryId, ownerId, payload, conn = db) {
    await conn.query('INSERT INTO dormitory_revisions (dormitory_id, owner_id, payload) VALUES (?, ?, ?)',
        [dormitoryId, ownerId, payload]);
}

async function updatePayload(id, payload, conn = db) {
    await conn.query('UPDATE dormitory_revisions SET payload = ?, submitted_at = NOW() WHERE id = ?', [payload, id]);
}

// status เป็น approved หรือ rejected ส่วน reason จะมีเฉพาะกรณีถูกปฏิเสธ
async function setReviewed(id, { status, reviewerId, reason = null }, conn = db) {
    await conn.query(
        'UPDATE dormitory_revisions SET status = ?, rejection_reason = ?, reviewed_at = NOW(), reviewed_by = ? WHERE id = ?',
        [status, reason, reviewerId, id]);
}

async function listPending() {
    const [rows] = await db.query(
        `SELECT r.id, r.dormitory_id, r.submitted_at, d.name AS dormitory_name, r.payload
         FROM dormitory_revisions r JOIN dormitories d ON d.id = r.dormitory_id
         WHERE r.status = 'pending' ORDER BY r.id`);
    return rows;
}

module.exports = { findPending, findLatest, insert, updatePayload, setReviewed, listPending };
