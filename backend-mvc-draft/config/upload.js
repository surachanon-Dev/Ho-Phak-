// ตั้งค่าการอัปโหลดไฟล์ด้วย multer
// - รูปหอพักเก็บใน uploads/ และเปิดเป็น static ได้ เพราะนักศึกษาต้องเห็นรูป
// - เอกสารยืนยันตัวตนเก็บใน private_uploads/ ไม่เปิดเป็น static เพราะเป็นข้อมูลส่วนตัว
//   admin เปิดดูได้ผ่าน endpoint ที่ตรวจสิทธิ์เท่านั้น
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { AppError } = require('../utils/AppError');

const ROOT = path.join(__dirname, '..');
const PUBLIC_UPLOAD_DIR = path.join(ROOT, 'uploads');
const PRIVATE_UPLOAD_DIR = path.join(ROOT, 'private_uploads');

fs.mkdirSync(PUBLIC_UPLOAD_DIR, { recursive: true });
fs.mkdirSync(PRIVATE_UPLOAD_DIR, { recursive: true });

const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const DOCUMENT_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];

// ตั้งชื่อไฟล์ใหม่ด้วย UUID เพื่อไม่ให้ชื่อจาก client ไปปนกับไฟล์อื่น
function makeStorage(dir) {
    return multer.diskStorage({
        destination: dir,
        filename: (req, file, cb) => {
            cb(null, crypto.randomUUID() + path.extname(file.originalname).toLowerCase());
        },
    });
}

function fileFilter(allowedTypes, message) {
    return (req, file, cb) => {
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new AppError(400, message));
        }
    };
}

const imageUpload = multer({
    storage: makeStorage(PUBLIC_UPLOAD_DIR),
    limits: { fileSize: 5 * 1024 * 1024, files: 5 },
    fileFilter: fileFilter(IMAGE_TYPES, 'รองรับเฉพาะไฟล์รูป jpg, png, webp'),
});

const documentUpload = multer({
    storage: makeStorage(PRIVATE_UPLOAD_DIR),
    limits: { fileSize: 10 * 1024 * 1024, files: 1 },
    fileFilter: fileFilter(DOCUMENT_TYPES, 'เอกสารต้องเป็นไฟล์ pdf, jpg หรือ png'),
});

// แปลง error ของ multer ให้เป็น AppError เพื่อให้ errorHandler ตอบ 400
function handleUpload(middleware) {
    return (req, res, next) => {
        middleware(req, res, (err) => {
            if (!err) return next();
            if (err instanceof multer.MulterError) {
                const message = err.code === 'LIMIT_FILE_SIZE'
                    ? 'ไฟล์มีขนาดใหญ่เกินกำหนด'
                    : 'จำนวนไฟล์หรือชื่อฟิลด์ไม่ถูกต้อง';
                return next(new AppError(400, message));
            }
            next(err);
        });
    };
}

// ลบไฟล์ที่อัปโหลดไปแล้ว ใช้เมื่อบันทึกลงฐานข้อมูลไม่สำเร็จ
function removeFiles(files) {
    for (const file of files) {
        fs.unlink(file.path, () => {});
    }
}

module.exports = {
    ROOT, PUBLIC_UPLOAD_DIR, PRIVATE_UPLOAD_DIR, imageUpload, documentUpload, handleUpload, removeFiles,
};
