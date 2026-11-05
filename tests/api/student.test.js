/**
 * API Test: Student (User) module (search, zone filter, distance, verified dorms only)
 */
const A = require('../helpers/api');
const { haversineKm } = require('../helpers/geo');
const { db, cleanup, close } = require('../helpers/db');

// Reference point for distance checks (change it to the university's coordinates)
const ORIGIN = { lat: 16.4747, lng: 102.8230 };

let student, approvedOwner, pendingOwner;
const ids = {};

async function userId(username) {
  const [rows] = await db().query('SELECT id FROM users WHERE username = ?', [username]);
  return rows[0].id;
}
async function makeDorm(owner, extra) {
  const data = A.dormData(extra);
  const res = await A.createDorm(owner.token, data);
  if (![200, 201].includes(res.status)) throw new Error(`Create dorm failed: ${res.status}`);
  const [rows] = await db().query('SELECT id FROM dormitories WHERE name = ?', [data.name]);
  return A.idOf(res) || rows[0].id;
}

beforeAll(async () => {
  student = await A.newUser('user');
  approvedOwner = await A.newUser('owner');
  pendingOwner = await A.newUser('owner');

  // Set the verification status in the DB directly, so this file does not depend on the admin API
  await db().query("INSERT INTO verifications (owner_id, document_url, status) VALUES (?, 'qa/doc.pdf', 'approved')", [await userId(approvedOwner.username)]);
  await db().query("INSERT INTO verifications (owner_id, document_url, status) VALUES (?, 'qa/doc.pdf', 'pending')", [await userId(pendingOwner.username)]);

  ids.near = await makeDorm(approvedOwner, { zone: 'หน้ามอ', latitude: 16.4760, longitude: 102.8240 });
  ids.far = await makeDorm(approvedOwner, { zone: 'หลังมอ', latitude: 16.4500, longitude: 102.8000 });
  ids.hidden = await makeDorm(pendingOwner, { zone: 'หน้ามอ' });
});
afterAll(async () => {
  await cleanup();
  await close();
});

const list = (query = {}) => A.auth(A.call(A.EP.student.listDorms), student.token).query(query);

test('STU-01 dorm list returns 200 and an array', async () => {
  const res = await list();
  expect(res.status).toBe(200);
  expect(Array.isArray(A.listOf(res))).toBe(true);
});

test('STU-02 dorms of an approved owner are shown', async () => {
  const shown = A.listOf(await list()).map((d) => Number(d.id));
  expect(shown).toEqual(expect.arrayContaining([Number(ids.near), Number(ids.far)]));
});

test('STU-03 dorms of an unapproved (pending) owner are hidden', async () => {
  const shown = A.listOf(await list()).map((d) => Number(d.id));
  expect(shown).not.toContain(Number(ids.hidden));
});

test('STU-04 zone filter returns only that zone', async () => {
  const res = await list({ zone: 'หลังมอ' });
  const items = A.listOf(res);
  expect(res.status).toBe(200);
  expect(items.length).toBeGreaterThan(0);
  items.forEach((d) => expect(d.zone).toBe('หลังมอ'));
  expect(items.map((d) => Number(d.id))).toContain(Number(ids.far));
});

test('STU-05 an unknown zone returns 400 or an empty list', async () => {
  const res = await list({ zone: 'ไม่มีโซนนี้' });
  if (res.status === 200) expect(A.listOf(res).length).toBe(0);
  else expect(res.status).toBe(400);
});

test('STU-06 distance is correct (within 5%) and sorted nearest first', async () => {
  const res = await list({ lat: ORIGIN.lat, lng: ORIGIN.lng });
  expect(res.status).toBe(200);
  const items = A.listOf(res).filter((d) => A.pick(d, A.EP.fields.distancePaths) !== undefined);
  if (items.length === 0) {
    console.warn('STU-06: the API returns no distance field, so the distance check was skipped');
    return;
  }
  items.forEach((d) => {
    const expected = haversineKm(ORIGIN.lat, ORIGIN.lng, Number(d.latitude), Number(d.longitude));
    const got = Number(A.pick(d, A.EP.fields.distancePaths));
    const gotKm = got > 50 ? got / 1000 : got; // in case the API returns meters
    expect(Math.abs(gotKm - expected)).toBeLessThanOrEqual(Math.max(expected * 0.05, 0.05));
  });
  const ds = items.map((d) => Number(A.pick(d, A.EP.fields.distancePaths)));
  expect(ds).toEqual([...ds].sort((a, b) => a - b));
});

test('STU-07 detail of an approved dorm returns full data', async () => {
  const res = await A.auth(A.call(A.EP.student.dormDetail, { id: ids.near }), student.token);
  expect(res.status).toBe(200);
  const d = res.body.data || res.body.dormitory || res.body;
  ['name', 'zone', 'latitude', 'longitude', 'price'].forEach((k) => expect(d).toHaveProperty(k));
});

test('STU-08 detail of a non-existent id returns 404', async () => {
  const res = await A.auth(A.call(A.EP.student.dormDetail, { id: 99999999 }), student.token);
  expect(res.status).toBe(404);
});

test('STU-09 detail of an unapproved dorm cannot be opened', async () => {
  const res = await A.auth(A.call(A.EP.student.dormDetail, { id: ids.hidden }), student.token);
  expect([403, 404]).toContain(res.status);
});

test('STU-10 the response does not leak the owner\'s password hash', async () => {
  const res = await list();
  expect(JSON.stringify(res.body)).not.toMatch(/\$argon2|"password"/);
});
