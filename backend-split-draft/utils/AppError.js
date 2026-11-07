// error ที่รู้ว่าควรตอบ status อะไร service จะ throw ตัวนี้ แล้ว errorHandler แปลงเป็น response
class AppError extends Error {
    constructor(statusCode, message) {
        super(message);
        this.statusCode = statusCode;
    }
}

module.exports = { AppError };
