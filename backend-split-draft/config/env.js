// อ่าน key จาก .env และหยุดทำงานถ้ายังไม่ได้ตั้งค่า
const JWT_KEY = process.env.JWT_KEY;
if (!JWT_KEY) {
    throw new Error('ยังไม่ได้ตั้งค่า JWT_KEY ใน .env');
}

module.exports = { JWT_KEY };
