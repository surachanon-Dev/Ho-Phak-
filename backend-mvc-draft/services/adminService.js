const crypto = require('crypto');
const argon2 = require('@node-rs/argon2');
// service ของการทำงานของ admin ทุกการกระทำจะบันทึก admin_logs และแจ้งเตือนผู้เกี่ยวข้องในทรานแซกชันเดียวกัน
const dormitoryModel = require('../models/dormitoryModel');
const revisionModel = require('../models/revisionModel');
const amenityModel = require('../models/amenityModel');
const verificationModel = require('../models/verificationModel');
const userModel = require('../models/userModel');
const reviewModel = require('../models/reviewModel');
const reportModel = require('../models/reportModel');
const adminLogModel = require('../models/adminLogModel');
const notificationModel = require('../models/notificationModel');
const verificationService = require('./verificationService');
const dormitoryDocumentService = require('./dormitoryDocumentService');
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
        if (dorm.status === 'suspended') fail(409, 'หอพักนี้ถูกระงับอยู่แล้ว');
        await dormitoryModel.updateStatus(dorm.id,
            { status: 'suspended', statusReason: reason, changedBy: admin.id }, conn);
        // เก็บสถานะก่อนระงับไว้ใน log เพื่อคืนสถานะเดิมตอน restore
        await adminLogModel.insert(admin, 'dormitory.suspend', 'dormitory', dorm.id,
            { reason, from: dorm.status }, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_suspended', title: 'หอพักถูกระงับ', body: reason,
            relatedType: 'dormitory', relatedId: dorm.id,
        }, conn);
    });
}

const RESTORABLE_STATUSES = ['pending', 'published', 'changes_pending', 'rejected', 'hidden'];

async function restoreDormitory(rawId, admin) {
    await withTransaction(async (conn) => {
        const dorm = await lockDormitory(rawId, conn);
        if (dorm.status !== 'suspended') fail(409, 'หอพักนี้ไม่ได้ถูกระงับ');
        // คืนสถานะก่อนระงับ (หอที่ยังไม่เคยอนุมัติหรือที่เจ้าของซ่อนไว้ต้องไม่ขึ้นสาธารณะเอง)
        // ไม่มี log เดิม (ระงับก่อนมีการเก็บสถานะ) → กลับไปรอตรวจเพื่อความปลอดภัย
        const suspendLog = await adminLogModel.findLatest('dormitory.suspend', 'dormitory', dorm.id, conn);
        const nextStatus = RESTORABLE_STATUSES.includes(suspendLog?.from) ? suspendLog.from : 'pending';
        await dormitoryModel.updateStatus(dorm.id,
            { status: nextStatus, statusReason: null, changedBy: admin.id }, conn);
        await adminLogModel.insert(admin, 'dormitory.restore', 'dormitory', dorm.id, { to: nextStatus }, conn);
        await notificationModel.insert(dorm.owner_id, {
            type: 'dormitory_restored', title: 'หอพักถูกคืนสถานะแล้ว', body: dorm.name,
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
        await notificationModel.insert(target.id, {
            type: 'account_suspended', title: 'บัญชีถูกระงับ', body: reason,
            relatedType: 'user', relatedId: target.id,
        }, conn);
    });
}

// แอดมินรีเซ็ตรหัสผ่านให้ผู้ใช้ที่ลืมรหัส คืนรหัสชั่วคราวให้แอดมินแจ้งผู้ใช้
async function resetUserPassword(rawId, admin) {
    const temporary = temporaryPassword();
    await withTransaction(async (conn) => {
        const target = await lockUser(rawId, conn);
        if (target.role === 'admin') fail(403, 'Admin passwords cannot be reset here');
        await userModel.updatePasswordHash(target.id, argon2.hashSync(temporary), conn);
        await adminLogModel.insert(admin, 'user.reset_password', 'user', target.id, null, conn);
        // ไม่ใส่รหัสชั่วคราวในแจ้งเตือน (admin แจ้งผู้ใช้เอง)
        await notificationModel.insert(target.id, {
            type: 'password_reset', title: 'รหัสผ่านถูกรีเซ็ตโดย admin',
            body: 'ติดต่อ admin เพื่อรับรหัสผ่านชั่วคราว แล้วเปลี่ยนรหัสผ่านหลังเข้าสู่ระบบ',
            relatedType: 'user', relatedId: target.id,
        }, conn);
    });
    return temporary;
}

// รหัสชั่วคราว 10 ตัว มีตัวพิมพ์ใหญ่ เล็ก และตัวเลข (ตัดตัวที่สับสนง่าย เช่น 0 O 1 l)
function temporaryPassword() {
    const sets = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnpqrstuvwxyz', '23456789'];
    const all = sets.join('');
    const pick = (chars) => chars[crypto.randomInt(chars.length)];
    const out = sets.map(pick);
    while (out.length < 10) out.push(pick(all));
    for (let i = out.length - 1; i > 0; i--) {
        const j = crypto.randomInt(i + 1);
        [out[i], out[j]] = [out[j], out[i]];
    }
    return out.join('');
}

async function restoreUser(rawId, admin) {
    await withTransaction(async (conn) => {
        const target = await lockUser(rawId, conn);
        if (target.status !== 'suspended') fail(409, 'บัญชีนี้ไม่ได้ถูกระงับ');
        await userModel.restore(target.id, conn);
        await adminLogModel.insert(admin, 'user.restore', 'user', target.id, null, conn);
        await notificationModel.insert(target.id, {
            type: 'account_restored', title: 'บัญชีถูกคืนสถานะแล้ว', body: 'คุณใช้งานบัญชีได้ตามปกติ',
            relatedType: 'user', relatedId: target.id,
        }, conn);
    });
}

async function listReviews(status) {
    // pending/published เป็นชื่อเก่าของ open/kept (ก่อนเปลี่ยนให้รีวิวขึ้นทันที)
    const alias = { pending: 'open', published: 'kept' };
    const wanted = alias[status] ?? status;
    return reviewModel.listByStatus(['open', 'kept', 'hidden'].includes(wanted) ? wanted : 'open');
}

async function publishReview(rawId, admin) {
    await withTransaction(async (conn) => {
        const id = toInt(rawId);
        const review = id === null ? undefined : await reviewModel.findForUpdate(id, conn);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await reviewModel.setModeration(id, { status: 'published', reviewerId: admin.id }, conn);
        await reportModel.resolveForReview(id, conn);
        await adminLogModel.insert(admin, 'review.publish', 'review', id, null, conn);
        await notificationModel.insert(review.user_id, {
            type: 'review_kept', title: 'รีวิวของคุณยังแสดงอยู่', body: 'admin ตรวจแล้วและคงรีวิวไว้',
            relatedType: 'review', relatedId: id,
        }, conn);
    });
}

async function hideReview(rawId, admin, rawReason) {
    const reason = requireReason(rawReason, 'ต้องระบุเหตุผลการซ่อนรีวิว');
    await withTransaction(async (conn) => {
        const id = toInt(rawId);
        const review = id === null ? undefined : await reviewModel.findForUpdate(id, conn);
        if (!review) fail(404, 'ไม่พบรีวิว');
        await reviewModel.setModeration(id, { status: 'hidden', reason, reviewerId: admin.id }, conn);
        await reportModel.resolveForReview(id, conn);
        await adminLogModel.insert(admin, 'review.hide', 'review', id, { reason }, conn);
        await notificationModel.insert(review.user_id, {
            type: 'review_hidden', title: 'รีวิวของคุณถูกซ่อน', body: reason,
            relatedType: 'review', relatedId: id,
        }, conn);
    });
}

async function logs() {
    return adminLogModel.listRecent();
}

async function verificationDocument(rawId) {
    return verificationService.getDocumentFile(rawId);
}

async function dormitoryDocument(rawDormitoryId) {
    return dormitoryDocumentService.getFileForAdmin(rawDormitoryId);
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

// คำขอยืนยันตัวตนตามสถานะ (pending | approved | rejected)
const VERIFICATION_STATUSES = ['pending', 'approved', 'rejected'];

async function verifications(status = 'pending') {
    if (!VERIFICATION_STATUSES.includes(status)) fail(400, 'สถานะคำขอไม่ถูกต้อง');
    return verificationModel.listByStatus(status);
}

// ---- สิ่งอำนวยความสะดวก (amenities) ----
function amenityName(value) {
    const name = typeof value === 'string' ? value.trim() : '';
    if (name.length === 0 || name.length > 100) fail(400, 'ชื่อสิ่งอำนวยความสะดวกต้องมี 1–100 ตัวอักษร');
    return name;
}

async function amenityOrFail(rawId) {
    const id = toInt(rawId);
    const amenity = id === null ? undefined : await amenityModel.findById(id);
    if (!amenity) fail(404, 'ไม่พบสิ่งอำนวยความสะดวกนี้');
    return amenity;
}

async function listAmenities() {
    return amenityModel.listAll();
}

async function createAmenity(admin, rawName) {
    const name = amenityName(rawName);
    return withTransaction(async (conn) => {
        const id = await amenityModel.insert(name, conn);
        await adminLogModel.insert(admin, 'amenity.create', 'amenity', id, { name }, conn);
        return id;
    });
}

async function renameAmenity(rawId, admin, rawName) {
    const amenity = await amenityOrFail(rawId);
    const name = amenityName(rawName);
    await withTransaction(async (conn) => {
        await amenityModel.rename(amenity.id, name, conn);
        await adminLogModel.insert(admin, 'amenity.rename', 'amenity', amenity.id,
            { from: amenity.name, to: name }, conn);
        // แจ้งเจ้าของหอที่ใช้สิ่งอำนวยความสะดวกนี้ว่าชื่อเปลี่ยน
        for (const ownerId of await amenityModel.ownerIdsUsing(amenity.id, conn)) {
            await notificationModel.insert(ownerId, {
                type: 'amenity_renamed', title: 'ชื่อสิ่งอำนวยความสะดวกเปลี่ยน', body: `${amenity.name} → ${name}`,
                relatedType: 'amenity', relatedId: amenity.id,
            }, conn);
        }
    });
}

async function deleteAmenity(rawId, admin) {
    const amenity = await amenityOrFail(rawId);
    await withTransaction(async (conn) => {
        // ต้องหาเจ้าของก่อนลบ เพราะลบแล้วความสัมพันธ์กับหอหายตาม FK
        const ownerIds = await amenityModel.ownerIdsUsing(amenity.id, conn);
        await amenityModel.remove(amenity.id, conn);
        await adminLogModel.insert(admin, 'amenity.delete', 'amenity', amenity.id,
            { name: amenity.name }, conn);
        for (const ownerId of ownerIds) {
            await notificationModel.insert(ownerId, {
                type: 'amenity_deleted', title: 'สิ่งอำนวยความสะดวกถูกลบ',
                body: `${amenity.name} ถูกเอาออกจากหอของคุณ`,
                relatedType: 'amenity', relatedId: amenity.id,
            }, conn);
        }
    });
}

module.exports = {
  verifications, listAmenities, createAmenity, renameAmenity, deleteAmenity,
    queue, approveDormitory, rejectDormitory, suspendDormitory, restoreDormitory,
    approveVerification, rejectVerification, suspendUser, restoreUser, resetUserPassword,
    listReviews, publishReview, hideReview, logs, listDormitories, listUsers, verificationDocument, dormitoryDocument,
};
