const mysql = require('mysql2/promise');

let pool;
function db() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST || '127.0.0.1',
      port: Number(process.env.DB_PORT || 3306),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'hopak',
      charset: 'utf8mb4',
      connectionLimit: 2,
    });
  }
  return pool;
}

/** Delete only test data (users whose username starts with TEST_PREFIX, except the admin) */
async function cleanup() {
  const prefix = (process.env.TEST_PREFIX || 'qa_').replace(/_/g, '\\_') + '%';
  const admin = process.env.ADMIN_USERNAME || 'qa_admin';
  const [rows] = await db().query('SELECT id FROM users WHERE username LIKE ? AND username <> ?', [prefix, admin]);
  const ids = rows.map((r) => r.id);
  if (ids.length) {
    await db().query('DELETE FROM verifications WHERE owner_id IN (?)', [ids]);
    await db().query('DELETE FROM dormitories WHERE owner_id IN (?)', [ids]);
    await db().query('DELETE FROM users WHERE id IN (?)', [ids]);
  }
  return ids.length;
}

async function close() {
  if (pool) await pool.end();
  pool = undefined;
}

module.exports = { db, cleanup, close };
