const db = require('../config/db');

// รันงานในทรานแซกชันเดียว ถ้าพังจะ rollback ทั้งหมด
async function withTransaction(work) {
    const conn = await db.getConnection();
    try {
        await conn.beginTransaction();
        const result = await work(conn);
        await conn.commit();
        return result;
    } catch (err) {
        await conn.rollback();
        throw err;
    } finally {
        conn.release();
    }
}

module.exports = { withTransaction };
