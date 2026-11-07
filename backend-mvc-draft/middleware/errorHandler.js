// จุดเดียวที่แปลง error เป็น response ทุก route ใช้ร่วมกัน
// ต้องวางหลัง route ทั้งหมดใน App.js
function errorHandler(err, req, res, next) {
    // body ที่ส่งมาเป็น JSON ที่อ่านไม่ได้
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ message: 'รูปแบบ JSON ไม่ถูกต้อง' });
    }
    if (err.status) {
        return res.status(err.status).json({ message: err.message });
    }
    if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ message: 'ข้อมูลซ้ำกับที่มีอยู่แล้ว' });
    }
    console.error(err);
    res.status(500).json({ message: 'DB error' });
}

function notFound(req, res) {
    res.status(404).json({ message: 'ไม่พบ API นี้' });
}

module.exports = { errorHandler, notFound };
