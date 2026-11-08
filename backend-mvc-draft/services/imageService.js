// service ของรูปหอพักที่เจ้าของอัปโหลด
const fs = require('fs');
const path = require('path');
const imageModel = require('../models/imageModel');
const { ROOT, removeFiles } = require('../config/upload');
const { fail } = require('../utils/AppError');
const { toInt } = require('../utils/validators');

const MAX_IMAGES_PER_DORMITORY = 10;

// files มาจาก multer แล้ว และ req.dormitory ถูกตรวจว่าเป็นของ owner แล้ว
async function addImages(dormitoryId, files) {
    if (!files || files.length === 0) fail(400, 'กรุณาเลือกรูปอย่างน้อย 1 รูป');

    const current = await imageModel.countForDormitory(dormitoryId);
    if (current + files.length > MAX_IMAGES_PER_DORMITORY) {
        removeFiles(files);
        fail(400, `หอพักมีรูปได้ไม่เกิน ${MAX_IMAGES_PER_DORMITORY} รูป`);
    }

    const rows = files.map((file, index) => [dormitoryId, `/uploads/${file.filename}`, current + index]);
    try {
        await imageModel.insertMany(rows);
    } catch (err) {
        // บันทึกฐานไม่สำเร็จ ลบไฟล์ที่เพิ่งอัปโหลดไม่ให้เหลือไฟล์ค้าง
        removeFiles(files);
        throw err;
    }
    return files.length;
}

async function removeImage(rawDormitoryId, rawImageId, ownerId) {
    const dormitoryId = toInt(rawDormitoryId);
    const imageId = toInt(rawImageId);
    const image = dormitoryId === null || imageId === null
        ? undefined
        : await imageModel.findOwnedImage(imageId, dormitoryId, ownerId);
    if (!image) fail(404, 'ไม่พบรูป');

    await imageModel.deleteById(imageId);
    fs.unlink(path.join(ROOT, image.file_path), () => {});
}

module.exports = { addImages, removeImage };
