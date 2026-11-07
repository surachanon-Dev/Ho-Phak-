// model ของตาราง messages
const db = require('../config/db');

async function listByConversation(conversationId) {
    const [rows] = await db.query(
        'SELECT id, sender_id, body, sent_at, read_at FROM messages WHERE conversation_id = ? ORDER BY id ASC',
        [conversationId]);
    return rows;
}

// อ่านแล้วเฉพาะข้อความของอีกฝ่าย
async function markRead(conversationId, userId) {
    await db.query(
        'UPDATE messages SET read_at = NOW() WHERE conversation_id = ? AND sender_id <> ? AND read_at IS NULL',
        [conversationId, userId]);
}

async function insert(conversationId, senderId, body) {
    const [result] = await db.query(
        'INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)',
        [conversationId, senderId, body]);
    return result.insertId;
}

module.exports = { listByConversation, markRead, insert };
