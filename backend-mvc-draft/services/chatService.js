// service ของแชทระหว่างนักศึกษากับเจ้าของหอ
const conversationModel = require('../models/conversationModel');
const messageModel = require('../models/messageModel');
const dormitoryService = require('./dormitoryService');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

// ดึงการสนทนาและตรวจว่าผู้ใช้เป็นคู่สนทนาเท่านั้น ไม่ใช่ตอบ 404
async function loadForParticipant(rawId, user) {
    const id = toInt(rawId);
    const conversation = id === null ? undefined : await conversationModel.findWithDormStatus(id);
    if (!conversation || (conversation.tenant_id !== user.id && conversation.owner_id !== user.id)) {
        fail(404, 'ไม่พบการสนทนา');
    }
    return conversation;
}

// เปิดแชทกับหอ: เจ้าของดึงจากฐานข้อมูล ไม่รับจาก client
async function open(userId, rawDormitoryId) {
    const dorm = await dormitoryService.getPublicOrFail(rawDormitoryId);
    const existing = await conversationModel.findByParticipants(dorm.id, userId, dorm.owner_id);
    if (existing) {
        await conversationModel.reopenForTenant(existing.id);
        return { id: existing.id, created: false };
    }
    const id = await conversationModel.insert(userId, dorm.owner_id, dorm.id);
    return { id, created: true };
}

async function list(user) {
    const side = user.role === 'owner' ? 'owner' : 'tenant';
    return conversationModel.listForSide(user.id, side);
}

async function messages(rawId, user) {
    const conversation = await loadForParticipant(rawId, user);
    const rows = await messageModel.listByConversation(conversation.id);
    await messageModel.markRead(conversation.id, user.id);
    const readOnly = conversation.dormitory_id === null || conversation.dormitory_status === 'suspended';
    return { messages: rows, read_only: readOnly };
}

async function send(rawId, user, body) {
    const conversation = await loadForParticipant(rawId, user);
    if (conversation.dormitory_id === null) fail(403, 'หอพักนี้ถูกลบแล้ว ส่งข้อความไม่ได้');
    if (conversation.dormitory_status === 'suspended') fail(403, 'หอพักถูกระงับ ส่งข้อความไม่ได้');
    const text = typeof body?.body === 'string' ? body.body.trim() : '';
    if (!text || text.length > 2000) fail(400, 'ข้อความต้องมี 1–2000 ตัวอักษร');
    return messageModel.insert(conversation.id, user.id, text);
}

// ลบแชทจากรายการของตัวเองเท่านั้น อีกฝ่ายยังเห็นอยู่
async function remove(rawId, user) {
    const conversation = await loadForParticipant(rawId, user);
    const side = conversation.tenant_id === user.id ? 'tenant' : 'owner';
    await conversationModel.markDeleted(conversation.id, side);
}

module.exports = { open, list, messages, send, remove };
