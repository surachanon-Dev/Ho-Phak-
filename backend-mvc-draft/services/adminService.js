// service ของการทำงานของ admin ทุกการกระทำจะบันทึก admin_logs และแจ้งเตือนผู้เกี่ยวข้องในทรานแซกชันเดียวกัน
const dormitoryModel = require('../models/dormitoryModel');
const revisionModel = require('../models/revisionModel');
const amenityModel = require('../models/amenityModel');
const verificationModel = require('../models/verificationModel');
const userModel = require('../models/userModel');
const reviewModel = require('../models/reviewModel');
const adminLogModel = require('../models/adminLogModel');
const notificationModel = require('../models/notificationModel');
const { withTransaction } = require('../utils/transaction');
const { fail } = require('../utils/AppError');
const { toInt, optionalText, parseDormitory } = require('../utils/validators');

function requireReason(raw, message) {
    const reason = optionalText(raw, 1000);
    if (!reason) fail(400, message);
    return reason;
}

async function lockDormitory(rawId, conn) {
    const id = toInt(rawId);
    const dorm = id === null ? undefined : await dormitoryModel.findForUpdate(id, conn);
    if (!dorm) fail(404, 'ไม่พบหอพัก');
    return dorm;
}

async function queue() {
    return {
        new_dormitories: await dormitoryModel.listPendingNew(),
        revisions: await revisionModel.listPending(),
        verifications: await verificationModel.listPending(),
    };
}

// หอใหม่ (pending) หรือฉบับแก้ไขที่รอตรวจ (changes_pending)
async function approveDormitory(rawId, admin) {
    await withTransaction(async (conn) => {
        const dorm = await lockDormitory(rawId, conn);

        if (dorm.status === 'pending') {
            await dormitoryModel.updateStatus(dorm.id,
                { status: 'published', rejectionReason: null, changedBy: admin.id }, conn);
        } else {
            const revision = await revisionModel.findPending(dorm.id, conn, true);
            if (!revision) fail(409, 'หอพักนี้ไม่มีรายการรอตรวจ');
            const data = parseDormitory(JSON.parse(revision.payload));
            await dormitoryModel.updateFields(dorm.id, data, conn);
            await amenityModel.replaceForDormitory(dorm.id, data.amenity_ids, conn);
            // หอที่เผยแพร่อยู่แล้วกลับไปเผยแพร่ ส่วนหอที่ซ่อนอยู่คงสถานะซ่อนไว้
            const nextStatus = dorm.status === 'changes_pending' ? 'published' : dorm.status;
            await dormitoryModel.updateStatus(dorm.id, { status: nextStatus }, conn);
            await revisionModel.setReviewed(revision.id, { status: 'approved', reviewerId: admin.id }, conn);
        }

        await adminLogModel.insert(admin, 'dormitory.approve', 'dormitory', dorm.id, { from: dorm.status }, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_approved', title: 'หอพักได้รับการอนุมัติ', body: dorm.name,
            relatedType: 'dormitory', relatedId: dorm.id,
        }, conn);
    });
}

async function rejectDormitory(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการปฏิเสธ');
    await withTransaction(async (conn) => {
        const dorm = await lockDormitory(rawId, conn);

        if (dorm.status === 'pending') {
            await dormitoryModel.updateStatus(dorm.id,
                { status: 'rejected', rejectionReason: reason, changedBy: admin.id }, conn);
        } else {
            const revision = await revisionModel.findPending(dorm.id, conn, true);
            if (!revision) fail(409, 'หอพักนี้ไม่มีรายการรอตรวจ');
            await revisionModel.setReviewed(revision.id, { status: 'rejected', reviewerId: admin.id, reason }, conn);
            if (dorm.status === 'changes_pending') {
                await dormitoryModel.updateStatus(dorm.id, { status: 'published' }, conn);
            }
        }

        await adminLogModel.insert(admin, 'dormitory.reject', 'dormitory', dorm.id, { reason }, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_rejected', title: 'หอพักไม่ผ่านการตรวจ', body: reason,
            relatedType: 'dormitory', relatedId: dorm.id,
        }, conn);
    });
}

async function suspendDormitory(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการระงับ');
    await withTransaction(async (conn) => {
        const dorm = await lockDormitory(rawId, conn);
        await dormitoryModel.updateStatus(dorm.id,
            { status: 'suspended', statusReason: reason, changedBy: admin.id }, conn);
        await adminLogModel.insert(admin, 'dormitory.suspend', 'dormitory', dorm.id, { reason }, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_suspended', title: 'หอพักถูกระงับ', body: reason,
            relatedType: 'dormitory', relatedId: dorm.id,
        }, conn);
    });
}

async function restoreDormitory(rawId, admin) {
    await withTransaction(async (conn) => {
        const dorm = await lockDormitory(rawId, conn);
        if (dorm.status !== 'suspended') fail(409, 'หอพักนี้ไม่ได้ถูกระงับ');
        await dormitoryModel.updateStatus(dorm.id,
            { status: 'published', statusReason: null, changedBy: admin.id }, conn);
        await adminLogModel.insert(admin, 'dormitory.restore', 'dormitory', dorm.id, null, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_restored', title: 'หอพักกลับมาแสดงแล้ว', body: dorm.name,
            relatedType: 'dormitory', relatedId: dorm.id,
        }, conn);
    });
}

async function lockVerification(rawId, conn) {
    const id = toInt(rawId);
    const verification = id === null ? undefined : await verificationModel.findForUpdate(id, conn);
    if (!verification) fail(404, 'ไม่พบคำขอ');
    if (verification.status !== 'pending') fail(409, 'คำขอนี้ตรวจไปแล้ว');
    return verification;
}

async function approveVerification(rawId, admin) {
    await withTransaction(async (conn) => {
        const verification = await lockVerification(rawId, conn);
        await verificationModel.setReviewed(verification.id, { status: 'approved', reviewerId: admin.id }, conn);
        // อนุมัติแล้วตั้ง is_verified ในทรานแซกชันเดียวกัน
        await userModel.setVerified(verification.owner_id, 1, conn);
        await adminLogModel.insert(admin, 'verification.approve', 'verification', verification.id,
            { owner_id: verification.owner_id }, conn);
        await notificationModel.insert(verification.owner_id, {
            type: 'verification_approved', title: 'ยืนยันตัวตนสำเร็จ', body: 'คุณสามารถเพิ่มหอพักได้แล้ว',
            relatedType: 'verification', relatedId: verification.id,
        }, conn);
    });
}

async function rejectVerification(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการปฏิเสธ');
    await withTransaction(async (conn) => {
        const verification = await lockVerification(rawId, conn);
        await verificationModel.setReviewed(verification.id, { status: 'rejected', reviewerId: admin.id, reason }, conn);
        await userModel.setVerified(verification.owner_id, 0, conn);
        await adminLogModel.insert(admin, 'verification.reject', 'verification', verification.id, { reason }, conn);
        await notificationModel.insert(verification.owner_id, {
            type: 'verification_rejected', title: 'ยืนยันตัวตนไม่ผ่าน', body: reason,
            relatedType: 'verification', relatedId: verification.id,
        }, conn);
    });
}

async function lockUser(rawId, conn) {
    const id = toInt(rawId);
    const user = id === null ? undefined : await userModel.findForUpdate(id, conn);
    if (!user) fail(404, 'ไม่พบผู้ใช้งาน');
    return user;
}

async function suspendUser(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการระงับ');
    await withTransaction(async (conn) => {
        const target = await lockUser(rawId, conn);
        if (target.role === 'admin') fail(403, 'ระงับบัญชี admin ไม่ได้');
        await userModel.suspend(target.id, reason, admin.id, conn);
        await adminLogModel.insert(admin, 'user.suspend', 'user', target.id, { reason }, conn);
    });
}

async function restoreUser(rawId, admin) {
    await withTransaction(async (conn) => {
        const target = await lockUser(rawId, conn);
        if (target.status !== 'suspended') fail(409, 'บัญชีนี้ไม่ได้ถูกระงับ');
        await userModel.restore(target.id, conn);
        await adminLogModel.insert(admin, 'user.restore', 'user', target.id, null, conn);
    });
}

async function listReviews(status) {
    const filter = ['pending', 'published', 'hidden'].includes(status) ? status : 'pending';
    return reviewModel.listByStatus(filter);
}

async function publishReview(rawId, admin) {
    await withTransaction(async (conn) => {
        const id = toInt(rawId);
        const review = id === null ? undefined : await reviewModel.findForUpdate(id, conn);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await reviewModel.setModeration(id, { status: 'published', reviewerId: admin.id }, conn);
        await adminLogModel.insert(admin, 'review.publish', 'review', id, null, conn);
    });
}

async function hideReview(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการซ่อนรีวิว');
    await withTransaction(async (conn) => {
        const id = toInt(rawId);
        const review = id === null ? undefined : await reviewModel.findForUpdate(id, conn);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await reviewModel.setModeration(id, { status: 'hidden', reason, reviewerId: admin.id }, conn);
        await adminLogModel.insert(admin, 'review.hide', 'review', id, { reason }, conn);
    });
}

async function logs() {
    return adminLogModel.listRecent();
}

const DORM_STATUSES = ['pending', 'published', 'changes_pending', 'rejected', 'hidden', 'suspended'];
const USER_ROLES = ['student', 'owner', 'admin'];
const USER_STATUSES = ['active', 'suspended'];

// รายการหอทั้งหมดสำหรับหน้า moderation กรองด้วย ?status= ได้
async function listDormitories(status) {
    if (status !== undefined && !DORM_STATUSES.includes(status)) {
        fail(400, 'status ของหอพักไม่ถูกต้อง');
    }
    return dormitoryModel.listForAdmin(status);
}

// รายการผู้ใช้ทั้งหมด กรองด้วย ?role= และ ?status= ได้
async function listUsers({ role, status }) {
    if (role !== undefined && !USER_ROLES.includes(role)) fail(400, 'role ไม่ถูกต้อง');
    if (status !== undefined && !USER_STATUSES.includes(status)) fail(400, 'status ของผู้ใช้ไม่ถูกต้อง');
    return userModel.listForAdmin({ role, status });
}

module.exports = {
    queue, approveDormitory, rejectDormitory, suspendDormitory, restoreDormitory,
    approveVerification, rejectVerification, suspendUser, restoreUser,
    listReviews, publishReview, hideReview, logs, listDormitories, listUsers,
};
