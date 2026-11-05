/**
 * Create (or reset) the admin account used for testing.
 * Admins should not be able to sign up through the API, so this writes to the DB directly.
 * Run: npm run seed
 */
require('dotenv').config();
const { hash: argonHash } = require('@node-rs/argon2'); // same library as the Backend (App.js)
const { db, close } = require('../helpers/db');

(async () => {
  const username = process.env.ADMIN_USERNAME || 'qa_admin';
  const password = process.env.ADMIN_PASSWORD || 'QaAdmin#2026';
  const hash = await argonHash(password); // default = Argon2id
  await db().query(
    `INSERT INTO users (username, password, role) VALUES (?, ?, 'admin')
     ON DUPLICATE KEY UPDATE password = VALUES(password), role = 'admin'`,
    [username, hash]
  );
  console.log(`Admin "${username}" is ready`);
  await close();
})().catch(async (e) => {
  console.error('Seed failed:', e.message);
  await close();
  process.exit(1);
});
