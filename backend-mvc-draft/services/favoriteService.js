// service ของรายการโปรดของนักศึกษา
const favoriteModel = require('../models/favoriteModel');
const dormitoryService = require('./dormitoryService');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

async function list(userId) {
    return favoriteModel.listByUser(userId);
}

// เพิ่มได้เฉพาะหอที่เผยแพร่แล้ว
async function add(userId, rawDormitoryId) {
    const dorm = await dormitoryService.getPublicOrFail(rawDormitoryId);
    await favoriteModel.insertIgnore(userId, dorm.id);
}

async function remove(userId, rawDormitoryId) {
    const id = toInt(rawDormitoryId);
    const affected = id === null ? 0 : await favoriteModel.remove(userId, id);
    if (affected === 0) fail(404, 'ไม่พบรายการโปรด');
}

module.exports = { list, add, remove };
