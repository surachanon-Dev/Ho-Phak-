// service ของการยืนยันตัวตนเจ้าของหอ
const verificationModel = require('../models/verificationModel');
const userModel = require('../models/userModel');
const { withTransaction } = require('../utils/transaction');
const { fail } = require('../utils/AppError');
const { optionalText } = require('../utils/validators');

async function getMine(ownerId) {
    return (await verificationModel.findByOwner(ownerId)) || null;
}

// อัปโหลดไฟล์จริงยังไม่รองรับ ตอนนี้รับ URL ของเอกสารก่อน
async function submit(ownerId, rawDocumentUrl) {
    const documentUrl = optionalText(rawDocumentUrl, 255);
    if (!documentUrl) fail(400, 'กรุณาระบุ document_url');

    const current = await verificationModel.findByOwner(ownerId);
    if (current && current.status === 'pending') fail(409, 'มีคำขอที่รอตรวจอยู่แล้ว');
    if (current && current.status === 'approved') fail(409, 'ยืนยันตัวตนแล้ว');

    await withTransaction(async (conn) => {
        if (current) {
            await verificationModel.resubmit(current.id, documentUrl, conn);
        } else {
            await verificationModel.insert(ownerId, documentUrl, conn);
        }
        // ระหว่างรอตรวจ เจ้าของยังใช้ฟังก์ชันเจ้าของไม่ได้
        await userModel.setVerified(ownerId, 0, conn);
    });
}

module.exports = { getMine, submit };
