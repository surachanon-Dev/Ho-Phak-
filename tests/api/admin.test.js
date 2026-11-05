/**
 * API Test: Admin module (Verification: Pending / Approved / Rejected)
 */
const A = require('../helpers/api');
const { db, cleanup, close } = require('../helpers/db');

let admin, owner1, owner2, student;

async function verificationIdOf(username) {
  const [rows] = await db().query(
    'SELECT v.id FROM verifications v JOIN users u ON u.id = v.owner_id WHERE u.username = ? ORDER BY v.id DESC LIMIT 1',
    [username]
  );
  return rows[0] && rows[0].id;
}
async function statusOf(id) {
  const [rows] = await db().query('SELECT status FROM verifications WHERE id = ?', [id]);
  return rows[0].status;
}
const setStatus = (token, id, status) =>
  A.auth(A.call(A.EP.admin.updateVerification, { id }), token).send({ status });

beforeAll(async () => {
  admin = await A.adminToken();
  owner1 = await A.newUser('owner');
  owner2 = await A.newUser('owner');
  student = await A.newUser('user');
  await A.submitVerification(owner1.token);
  await A.submitVerification(owner2.token);
  owner1.vid = await verificationIdOf(owner1.username);
  owner2.vid = await verificationIdOf(owner2.username);
});
afterAll(async () => {
  await cleanup();
  await close();
});

test('ADM-01 admin sees the pending request in the list', async () => {
  const res = await A.auth(A.call(A.EP.admin.listVerifications), admin).query({ status: 'pending' });
  expect(res.status).toBe(200);
  expect(A.listOf(res).map((v) => Number(v.id))).toContain(Number(owner1.vid));
});

test('ADM-02 status filter returns only pending', async () => {
  const res = await A.auth(A.call(A.EP.admin.listVerifications), admin).query({ status: 'pending' });
  A.listOf(res).forEach((v) => expect(v.status).toBe('pending'));
});

test('ADM-03 admin approves a request', async () => {
  const res = await setStatus(admin, owner1.vid, 'approved');
  expect(res.status).toBe(200);
  expect(await statusOf(owner1.vid)).toBe('approved');
});

test('ADM-04 admin rejects a request', async () => {
  const res = await setStatus(admin, owner2.vid, 'rejected');
  expect(res.status).toBe(200);
  expect(await statusOf(owner2.vid)).toBe('rejected');
});

test('ADM-05 an invalid status is rejected', async () => {
  const res = await setStatus(admin, owner1.vid, 'banana');
  expect(res.status).toBe(400);
  expect(await statusOf(owner1.vid)).toBe('approved');
});

test('ADM-06 an owner cannot approve themselves', async () => {
  const res = await setStatus(owner2.token, owner2.vid, 'approved');
  expect(res.status).toBe(403);
  expect(await statusOf(owner2.vid)).toBe('rejected');
});

test('ADM-07 a student cannot open the admin list', async () => {
  const res = await A.auth(A.call(A.EP.admin.listVerifications), student.token);
  expect(res.status).toBe(403);
});

test('ADM-08 a non-existent verification id returns 404', async () => {
  const res = await setStatus(admin, 99999999, 'approved');
  expect(res.status).toBe(404);
});
