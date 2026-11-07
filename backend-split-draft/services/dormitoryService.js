// service เก็บกฎของหอพัก ทั้งการตรวจข้อมูลและการเช็กว่าหอเป็นของ owner คนนี้
const dormitoryModel = require('../models/dormitoryModel');
const { AppError } = require('../utils/AppError');

const ZONES = ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'];

// ตรวจข้อมูลหอพักทั้ง POST และ PUT แล้วคืนเฉพาะ field ที่ใช้
function validateDormitory(body) {
    const { name, zone, latitude, longitude, price_per_month } = body;
    if (!name || !zone || latitude == null || longitude == null || price_per_month == null) {
        throw new AppError(400, 'กรอกข้อมูลให้ครบ');
    }
    if (!ZONES.includes(zone)) {
        throw new AppError(400, 'zone ไม่ถูกต้อง');
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        throw new AppError(400, 'พิกัดไม่ถูกต้อง');
    }
    if (!Number.isInteger(price_per_month) || price_per_month <= 0 || price_per_month > 1000000) {
        throw new AppError(400, 'ราคาต้องเป็นจำนวนเต็มระหว่าง 1 ถึง 1,000,000');
    }
    return { name, zone, latitude, longitude, price_per_month };
}

async function createDormitory(ownerId, body) {
    const data = validateDormitory(body);
    return dormitoryModel.insert(ownerId, data);
}

async function listDormitories(ownerId) {
    return dormitoryModel.findByOwner(ownerId);
}

async function getDormitory(id, ownerId) {
    const dormitory = await dormitoryModel.findOneByOwner(id, ownerId);
    if (!dormitory) {
        throw new AppError(404, 'ไม่พบหอพัก');
    }
    return dormitory;
}

async function updateDormitory(id, ownerId, body) {
    const data = validateDormitory(body);
    const affected = await dormitoryModel.update(id, ownerId, data);
    if (affected === 0) {
        throw new AppError(404, 'ไม่พบหอพัก');
    }
}

async function deleteDormitory(id, ownerId) {
    const affected = await dormitoryModel.remove(id, ownerId);
    if (affected === 0) {
        throw new AppError(404, 'ไม่พบหอพัก');
    }
}

module.exports = { createDormitory, listDormitories, getDormitory, updateDormitory, deleteDormitory };
