// service ของรีวิว (นักศึกษาเป็นคนเขียน ต้องผ่านการตรวจก่อนแสดง)
const reviewModel = require('../models/reviewModel');
const dormitoryService = require('./dormitoryService');
const { fail } = require('../utils/AppError');
const { toInt, optionalText } = require('../utils/validators');

function parseRating(value) {
    const rating = toInt(value);
    if (rating === null || rating < 1 || rating > 5) {
        fail(400, 'คะแนนต้องเป็นจำนวนเต็ม 1–5');
    }
    return rating;
}

async function create(rawDormitoryId, userId, body) {
    const dorm = await dormitoryService.getPublicOrFail(rawDormitoryId);
    const rating = parseRating(body?.rating);
    const text = optionalText(body?.body, 1000);
    try {
        return await reviewModel.insert(dorm.id, userId, rating, text);
    } catch (err) {
        if (err.code === 'ER_DUP_ENTRY') fail(409, 'คุณรีวิวหอนี้แล้ว แก้ไขรีวิวเดิมแทนได้');
        throw err;
    }
}

async function update(rawReviewId, userId, body) {
    const id = toInt(rawReviewId);
    const review = id === null ? undefined : await reviewModel.findOwn(id, userId);
    if (!review) fail(404, 'ไม่พบรีวิว');
    const rating = parseRating(body?.rating);
    await reviewModel.updateOwn(id, rating, optionalText(body?.body, 1000));
}

async function remove(rawReviewId, userId) {
    const id = toInt(rawReviewId);
    const affected = id === null ? 0 : await reviewModel.deleteOwn(id, userId);
    if (affected === 0) fail(404, 'ไม่พบรีวิว');
}

module.exports = { create, update, remove };
