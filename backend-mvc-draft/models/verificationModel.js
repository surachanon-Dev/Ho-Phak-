// model ของตาราง verifications (เอกสารยืนยันตัวตนของเจ้าของ)
const db = require('../config/db');

async function findByOwner(ownerId) {
    const [rows] = await db.query('SELECT * FROM verifications WHERE owner_id = ?', [ownerId]);
    return rows[0];
}

async function insert(ownerId, documentUrl, conn = db) {
    await conn.query(
        "INSERT INTO verifications (owner_id, document_url, status, submitted_at) VALUES (?, ?, 'pending', NOW())",
        [ownerId, documentUrl]);
}

// ส่งใหม่หลังถูกปฏิเสธ: ล้างข้อมูลการตรวจเดิมและกลับเป็น pending
async function resubmit(id, documentUrl, conn = db) {
    await conn.query(
        `UPDATE verifications SET document_url = ?, status = 'pending', submitted_at = NOW(),
         reviewed_at = NULL, reviewed_by = NULL, rejection_reason = NULL WHERE id = ?`,
        [documentUrl, id]);
}

async function findById(id) {
    const [rows] = await db.query('SELECT * FROM verifications WHERE id = ?', [id]);
    return rows[0];
}

async function findForUpdate(id, conn = db) {
    const [rows] = await conn.query('SELECT * FROM verifications WHERE id = ? FOR UPDATE', [id]);
    return rows[0];
}

// reason จะมีเฉพาะกรณีถูกปฏิเสธ
async function setReviewed(id, { status, reviewerId, reason = null }, conn = db) {
    await conn.query(
        'UPDATE verifications SET status = ?, reviewed_at = NOW(), reviewed_by = ?, rejection_reason = ? WHERE id = ?',
        [status, reviewerId, reason, id]);
}

async function listPending() {
    const [rows] = await db.query(
        `SELECT v.id, v.owner_id, v.document_url, v.submitted_at, u.phone AS owner_phone
         FROM verifications v JOIN users u ON u.id = v.owner_id WHERE v.status = 'pending' ORDER BY v.id`);
    return rows;
}

module.exports = { findByOwner, findById, insert, resubmit, findForUpdate, setReviewed, listPending };
