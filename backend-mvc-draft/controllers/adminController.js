// controller ของ admin ทุก route ผ่าน adminOnly มาแล้ว
const adminService = require('../services/adminService');

async function queue(req, res) {
    res.json(await adminService.queue());
}

async function approveDormitory(req, res) {
    await adminService.approveDormitory(req.params.id, req.user);
    res.json({ message: 'อนุมัติหอพักแล้ว' });
}

async function rejectDormitory(req, res) {
    await adminService.rejectDormitory(req.params.id, req.user, req.body?.reason);
    res.json({ message: 'ปฏิเสธรายการแล้ว' });
}

async function suspendDormitory(req, res) {
    await adminService.suspendDormitory(req.params.id, req.user, req.body?.reason);
    res.json({ message: 'ระงับหอพักแล้ว' });
}

async function restoreDormitory(req, res) {
    await adminService.restoreDormitory(req.params.id, req.user);
    res.json({ message: 'คืนสถานะหอพักแล้ว' });
}

async function approveVerification(req, res) {
    await adminService.approveVerification(req.params.id, req.user);
    res.json({ message: 'อนุมัติการยืนยันตัวตนแล้ว' });
}

async function rejectVerification(req, res) {
    await adminService.rejectVerification(req.params.id, req.user, req.body?.reason);
    res.json({ message: 'ปฏิเสธคำขอแล้ว' });
}

async function suspendUser(req, res) {
    await adminService.suspendUser(req.params.id, req.user, req.body?.reason);
    res.json({ message: 'ระงับบัญชีแล้ว' });
}

async function restoreUser(req, res) {
    await adminService.restoreUser(req.params.id, req.user);
    res.json({ message: 'คืนสถานะบัญชีแล้ว' });
}

async function listReviews(req, res) {
    const reviews = await adminService.listReviews(req.query.status);
    res.json({ reviews });
}

async function publishReview(req, res) {
    await adminService.publishReview(req.params.id, req.user);
    res.json({ message: 'เผยแพร่รีวิวแล้ว' });
}

async function hideReview(req, res) {
    await adminService.hideReview(req.params.id, req.user, req.body?.reason);
    res.json({ message: 'ซ่อนรีวิวแล้ว' });
}

// ส่งไฟล์เอกสารยืนยันตัวตนให้ admin ดู ไฟล์อยู่ในโฟลเดอร์ส่วนตัวจึงต้องผ่านตรงนี้เท่านั้น
async function verificationDocument(req, res) {
    const file = await adminService.verificationDocument(req.params.id);
    res.sendFile(file);
}

async function logs(req, res) {
    res.json({ logs: await adminService.logs() });
}

async function listDormitories(req, res) {
    const dormitories = await adminService.listDormitories(req.query.status);
    res.json({ dormitories });
}

async function listUsers(req, res) {
    const users = await adminService.listUsers(req.query);
    res.json({ users });
}

module.exports = {
    queue, approveDormitory, rejectDormitory, suspendDormitory, restoreDormitory,
    approveVerification, rejectVerification, suspendUser, restoreUser,
    listReviews, publishReview, hideReview, logs, listDormitories, listUsers, verificationDocument,
};
