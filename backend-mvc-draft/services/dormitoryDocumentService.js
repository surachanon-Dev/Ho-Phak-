// เอกสารความเป็นเจ้าของหอ: เจ้าของอัปโหลด และ admin เปิดดูได้เฉพาะตอนตรวจ
const path = require('path');
const dormitoryDocumentModel = require('../models/dormitoryDocumentModel');
const { ROOT, removeFiles } = require('../config/upload');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

const PRIVATE_PREFIX = 'private_uploads/';

// file มาจาก multer แล้ว (req.dormitory ถูกตรวจว่าเป็นของเจ้าของแล้วที่ middleware)
async function addForDormitory(dormitoryId, file) {
    if (!file) fail(400, 'กรุณาอัปโหลดเอกสารความเป็นเจ้าของหอ');
    const storedPath = `${PRIVATE_PREFIX}${file.filename}`;
    try {
        await dormitoryDocumentModel.insert(dormitoryId, storedPath, file.originalname);
    } catch (err) {
        removeFiles([file]);
        throw err;
    }
}

// คืน path ของไฟล์เอกสารฉบับล่าสุดของหอ สำหรับ admin เท่านั้น
async function getFileForAdmin(rawDormitoryId) {
    const id = toInt(rawDormitoryId);
    const document = id === null ? undefined : await dormitoryDocumentModel.latestForDormitory(id);
    if (!document) fail(404, 'หอนี้ยังไม่มีเอกสารความเป็นเจ้าของ');
    return path.join(ROOT, document.document_url);
}

module.exports = { addForDormitory, getFileForAdmin };
