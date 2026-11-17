// ตรวจว่าหอที่ระบุใน URL เป็นของ owner คนนี้ ก่อนรับไฟล์ เพื่อไม่ให้บันทึกไฟล์ของคนอื่นลงเครื่อง
const dormitoryModel = require('../models/dormitoryModel');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

async function requireOwnedDormitory(req, res, next) {
    const id = toInt(req.params.id);
    const dormitory = id === null ? undefined : await dormitoryModel.findOwned(id, req.user.id);
    if (!dormitory) fail(404, 'ไม่พบหอพัก');
    req.dormitory = dormitory;
    next();
}

module.exports = { requireOwnedDormitory };
