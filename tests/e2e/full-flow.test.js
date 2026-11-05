/**
 * E2E: the full data flow from the Sprint 4 plan
 * Owner signs up → creates a dorm → submits a document → Admin approves → Student finds the dorm
 * Each step depends on the one before it, so if one fails, the later steps fail too (by design).
 */
const A = require('../helpers/api');
const { db, cleanup, close } = require('../helpers/db');

const ctx = {};
const dormName = `${A.PREFIX}E2E หอทดสอบ ${Date.now()}`;

afterAll(async () => {
  await cleanup();
  await close();
});

const studentSearch = () =>
  A.auth(A.call(A.EP.student.listDorms), ctx.student.token).query({ zone: 'คชพลแลนด์' });

test('E2E-01 owner signs up and logs in', async () => {
  ctx.owner = await A.newUser('owner');
  expect(ctx.owner.token).toBeTruthy();
});

test('E2E-02 owner creates a dorm in คชพลแลนด์ zone', async () => {
  const res = await A.createDorm(ctx.owner.token, A.dormData({ name: dormName, zone: 'คชพลแลนด์', price: 2900 }));
  expect([200, 201]).toContain(res.status);
  const [rows] = await db().query('SELECT id FROM dormitories WHERE name = ?', [dormName]);
  ctx.dormId = A.idOf(res) || rows[0].id;
});

test('E2E-03 owner submits an ownership document', async () => {
  const res = await A.submitVerification(ctx.owner.token);
  expect([200, 201]).toContain(res.status);
});

test('E2E-04 before approval, the student cannot see the dorm', async () => {
  ctx.student = await A.newUser('user');
  const ids = A.listOf(await studentSearch()).map((d) => Number(d.id));
  expect(ids).not.toContain(Number(ctx.dormId));
});

test('E2E-05 admin sees the request and approves it', async () => {
  const admin = await A.adminToken();
  const list = await A.auth(A.call(A.EP.admin.listVerifications), admin).query({ status: 'pending' });
  const [rows] = await db().query(
    "SELECT v.id FROM verifications v JOIN users u ON u.id = v.owner_id WHERE u.username = ? AND v.status = 'pending'",
    [ctx.owner.username]
  );
  expect(A.listOf(list).map((v) => Number(v.id))).toContain(Number(rows[0].id));
  const res = await A.auth(A.call(A.EP.admin.updateVerification, { id: rows[0].id }), admin).send({ status: 'approved' });
  expect(res.status).toBe(200);
});

test('E2E-06 after approval, the student finds the dorm by searching คชพลแลนด์', async () => {
  const items = A.listOf(await studentSearch());
  const found = items.find((d) => Number(d.id) === Number(ctx.dormId));
  expect(found).toBeTruthy();
  expect(found.name).toBe(dormName);
  expect(Number(found.price)).toBe(2900);
});

test('E2E-07 the student opens the dorm detail page', async () => {
  const res = await A.auth(A.call(A.EP.student.dormDetail, { id: ctx.dormId }), ctx.student.token);
  expect(res.status).toBe(200);
});

test('E2E-08 owner deletes the dorm and the student can no longer find it', async () => {
  const del = await A.auth(A.call(A.EP.owner.deleteDorm, { id: ctx.dormId }), ctx.owner.token);
  expect([200, 204]).toContain(del.status);
  const ids = A.listOf(await studentSearch()).map((d) => Number(d.id));
  expect(ids).not.toContain(Number(ctx.dormId));
});
