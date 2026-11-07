const { AppError } = require('../utils/AppError');

// จุดเดียวที่แปลง error เป็น response ทุก route ใช้ร่วมกัน
// ต้องวางหลัง route ทั้งหมดใน App.js
function errorHandler(err, req, res, next) {
    if (err instanceof AppError) {
        return res.status(err.statusCode).json({ message: err.message });
    }
    // body ที่ส่งมาเป็น JSON ที่อ่านไม่ได้
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ message: 'รูปแบบ JSON ไม่ถูกต้อง' });
    }
    console.error(err);
    res.status(500).json({ message: 'DB error' });
}

module.exports = errorHandler;
