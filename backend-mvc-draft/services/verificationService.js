// service ของการยืนยันตัวตนเจ้าของหอ
const path = require('path');
const verificationModel = require('../models/verificationModel');
const userModel = require('../models/userModel');
const { withTransaction } = require('../utils/transaction');
const { fail } = require('../utils/AppError');
const { ROOT, removeFiles } = require('../config/upload');
const { toInt } = require('../utils/validators');

const PRIVATE_PREFIX = 'private_uploads/';

async function getMine(ownerId) {
    return (await verificationModel.findByOwner(ownerId)) || null;
}

// file มาจาก multer แล้ว เอกสารจะถูกเก็บในโฟลเดอร์ส่วนตัว
async function submit(ownerId, file) {
    if (!file) fail(400, 'กรุณาอัปโหลดไฟล์เอกสาร');
    const storedPath = `${PRIVATE_PREFIX}${file.filename}`;

    try {
        const current = await verificationModel.findByOwner(ownerId);
        if (current && current.status === 'pending') fail(409, 'มีคำขอที่รอตรวจอยู่แล้ว');
        if (current && current.status === 'approved') fail(409, 'ยืนยันตัวตนแล้ว');

        await withTransaction(async (conn) => {
            if (current) {
                await verificationModel.resubmit(current.id, storedPath, conn);
            } else {
                await verificationModel.insert(ownerId, storedPath, conn);
            }
            // ระหว่างรอตรวจ เจ้าของยังใช้ฟังก์ชันเจ้าของไม่ได้
            await userModel.setVerified(ownerId, 0, conn);
        });
    } catch (err) {
        // คำขอไม่ผ่าน ลบไฟล์ที่เพิ่งอัปโหลดไม่ให้ค้างในเครื่อง
        removeFiles([file]);
        throw err;
    }
}

// ไฟล์เอกสารสำหรับ admin เท่านั้น คืน path ที่อยู่ในโฟลเดอร์ส่วนตัว
async function getDocumentFile(rawId) {
    const id = toInt(rawId);
    const verification = id === null ? undefined : await verificationModel.findById(id);
    if (!verification) fail(404, 'ไม่พบคำขอ');
    if (!verification.document_url.startsWith(PRIVATE_PREFIX)) fail(404, 'ไม่มีไฟล์เอกสารในระบบ');
    return path.join(ROOT, verification.document_url);
}

module.exports = { getMine, submit, getDocumentFile };
