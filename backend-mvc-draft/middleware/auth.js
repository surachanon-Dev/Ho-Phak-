const jwt = require('jsonwebtoken');
const { JWT_KEY } = require('../config/env');
const userModel = require('../models/userModel');
const { fail } = require('../utils/AppError');

// ด่านที่ 1: ตรวจ token และโหลดสถานะล่าสุดจาก DB ทุกครั้ง
async function requireAuth(req, res, next) {
    const header = req.headers['authorization'];
    if (!header) fail(401, 'ม่ายมี header นะ');
    if (!header.startsWith('Bearer ')) fail(401, 'ต้องขึ้นต้นด้วย Bearer');

    let payload;
    try {
        payload = jwt.verify(header.split(' ')[1], JWT_KEY);
    } catch (err) {
        fail(401, err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง');
    }

    const user = await userModel.findAuthState(payload.id);
    if (!user) fail(401, 'ไม่พบผู้ใช้งาน');
    if (user.status !== 'active') fail(403, 'บัญชีนี้ถูกระงับ');

    req.user = user;
    next();
}

// ด่านที่ 2: ตรวจ role ของผู้ใช้
function requireRole(...roles) {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) fail(403, 'ไม่มีสิทธิ์เข้าถึง');
        next();
    };
}

// ด่านที่ 3: owner ต้องยืนยันตัวตนแล้ว
function requireVerifiedOwner(req, res, next) {
    if (!req.user.is_verified) fail(403, 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน');
    next();
}

const ownerOnly = [requireAuth, requireRole('owner'), requireVerifiedOwner];
const studentOnly = [requireAuth, requireRole('student')];
const adminOnly = [requireAuth, requireRole('admin')];
const chatOnly = [requireAuth, requireRole('student', 'owner')];

module.exports = { requireAuth, requireRole, requireVerifiedOwner, ownerOnly, studentOnly, adminOnly, chatOnly };
