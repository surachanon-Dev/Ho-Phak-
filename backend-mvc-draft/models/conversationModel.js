// model ของตาราง conversations
const db = require('../config/db');

// คอลัมน์ที่ใช้ในการกรองตามฝั่งผู้ใช้ (รับค่าจากโค้ดเท่านั้น ไม่รับจาก client)
const SIDE_COLUMNS = {
    tenant: { id: 'tenant_id', deletedAt: 'deleted_by_tenant_at' },
    owner: { id: 'owner_id', deletedAt: 'deleted_by_owner_at' },
};

async function findWithDormStatus(id) {
    const [rows] = await db.query(
        `SELECT c.*, d.status AS dormitory_status FROM conversations c
         LEFT JOIN dormitories d ON d.id = c.dormitory_id WHERE c.id = ?`, [id]);
    return rows[0];
}

async function findByParticipants(dormitoryId, tenantId, ownerId) {
    const [rows] = await db.query(
        'SELECT id FROM conversations WHERE dormitory_id = ? AND tenant_id = ? AND owner_id = ?',
        [dormitoryId, tenantId, ownerId]);
    return rows[0];
}

async function insert(tenantId, ownerId, dormitoryId) {
    const [result] = await db.query(
        'INSERT INTO conversations (tenant_id, owner_id, dormitory_id) VALUES (?, ?, ?)',
        [tenantId, ownerId, dormitoryId]);
    return result.insertId;
}

async function reopenForTenant(id) {
    await db.query('UPDATE conversations SET deleted_by_tenant_at = NULL WHERE id = ?', [id]);
}

// แชทที่ยังไม่ถูกลบจากฝั่งนี้ หรือมีข้อความใหม่หลังจากที่ลบไป
async function listForSide(userId, side) {
    const cols = SIDE_COLUMNS[side];
    const [rows] = await db.query(
        `SELECT c.id, c.dormitory_id, c.tenant_id, c.owner_id, d.name AS dormitory_name, d.status AS dormitory_status,
                (SELECT body FROM messages m WHERE m.conversation_id = c.id ORDER BY m.id DESC LIMIT 1) AS last_message,
                (SELECT MAX(sent_at) FROM messages m WHERE m.conversation_id = c.id) AS last_sent_at,
                (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id AND m.sender_id <> ? AND m.read_at IS NULL) AS unread_count
         FROM conversations c LEFT JOIN dormitories d ON d.id = c.dormitory_id
         WHERE c.${cols.id} = ?
           AND (c.${cols.deletedAt} IS NULL
                OR (SELECT MAX(sent_at) FROM messages m WHERE m.conversation_id = c.id) > c.${cols.deletedAt})
         ORDER BY last_sent_at DESC`,
        [userId, userId]);
    return rows;
}

// ทำเครื่องหมายว่าลบแชทจากฝั่งนี้แล้ว (side เป็น tenant หรือ owner)
async function markDeleted(id, side) {
    await db.query(`UPDATE conversations SET ${SIDE_COLUMNS[side].deletedAt} = NOW() WHERE id = ?`, [id]);
}

module.exports = { findWithDormStatus, findByParticipants, insert, reopenForTenant, listForSide, markDeleted, SIDE_COLUMNS };
