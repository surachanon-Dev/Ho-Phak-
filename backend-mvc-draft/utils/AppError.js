// error ที่รู้ว่าควรตอบ status อะไร errorHandler จะแปลงเป็น response
class AppError extends Error {
    constructor(status, message) {
        super(message);
        this.status = status;
    }
}

function fail(status, message) {
    throw new AppError(status, message);
}

module.exports = { AppError, fail };
