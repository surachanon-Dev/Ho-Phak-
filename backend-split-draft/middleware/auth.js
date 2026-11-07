const jwt = require('jsonwebtoken');
const { JWT_KEY } = require('../config/env');
const userModel = require('../models/userModel');
const { AppError } = require('../utils/AppError');

// ด่านที่ 1: ตรวจ header และ verify JWT
function requireAuth(req, res, next) {
    const header = req.headers['authorization'];
    if (!header) {
        throw new AppError(401, 'ม่ายมี header นะ');
    }
    if (!header.startsWith('Bearer ')) {
        throw new AppError(401, 'ต้องขึ้นต้นด้วย Bearer');
    }

    const token = header.split(' ')[1];
    try {
        req.user = jwt.verify(token, JWT_KEY);
    } catch (err) {
        const message = err.name === 'TokenExpiredError' ? 'token หมดอายุแล้ว' : 'token ไม่ถูกต้อง';
        throw new AppError(401, message);
    }
    next();
}

// ด่านที่ 2: ต้องเป็น owner
function requireOwner(req, res, next) {
    if (req.user.role !== 'owner') {
        throw new AppError(403, 'เฉพาะ owner เท่านั้น');
    }
    next();
}

// ด่านที่ 3: owner ต้องยืนยันตัวตนแล้ว ตรวจจาก DB ทุกครั้งเพื่อให้ได้ค่าล่าสุด
async function requireVerifiedOwner(req, res, next) {
    const user = await userModel.findVerification(req.user.id);
    if (!user) {
        throw new AppError(403, 'ไม่พบผู้ใช้งาน');
    }
    if (!user.is_verified) {
        throw new AppError(403, 'ผู้ใช้งานยังไม่ได้ยืนยันตัวตน');
    }
    next();
}

module.exports = { requireAuth, requireOwner, requireVerifiedOwner };
