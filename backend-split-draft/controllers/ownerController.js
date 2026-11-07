// controller ของ owner ทุก route ผ่าน middleware ของ owner มาแล้ว จึงใช้ req.user ได้เลย
const dormitoryService = require('../services/dormitoryService');
const { AppError } = require('../utils/AppError');

// แปลง id จาก URL ถ้าไม่ใช่ตัวเลขให้ตอบ 404 เหมือนไม่พบหอพัก
function parseId(value) {
    const id = Number(value);
    if (!Number.isInteger(id)) {
        throw new AppError(404, 'ไม่พบหอพัก');
    }
    return id;
}

// ใช้ทดสอบว่าผ่านด่านทั้งหมดแล้ว
function checkOwner(req, res) {
    res.json({ message: 'Welcome ครับ', user: req.user });
}

async function createDormitory(req, res) {
    const id = await dormitoryService.createDormitory(req.user.id, req.body || {});
    res.status(201).json({ message: 'เพิ่มหอพักสำเร็จ', id });
}

async function listDormitories(req, res) {
    const dormitories = await dormitoryService.listDormitories(req.user.id);
    res.json({ dormitories });
}

async function getDormitory(req, res) {
    const dormitory = await dormitoryService.getDormitory(parseId(req.params.id), req.user.id);
    res.json({ dormitory });
}

async function updateDormitory(req, res) {
    await dormitoryService.updateDormitory(parseId(req.params.id), req.user.id, req.body || {});
    res.json({ message: 'แก้ไขหอพักสำเร็จ' });
}

async function deleteDormitory(req, res) {
    await dormitoryService.deleteDormitory(parseId(req.params.id), req.user.id);
    res.json({ message: 'ลบหอพักสำเร็จ' });
}

module.exports = { checkOwner, createDormitory, listDormitories, getDormitory, updateDormitory, deleteDormitory };
