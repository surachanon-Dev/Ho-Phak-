/**
 * API Test: Owner module (dorm CRUD, coordinates, image upload, verification submission)
 */
const A = require('../helpers/api');
const { db, cleanup, close } = require('../helpers/db');

let ownerA, ownerB, student, dormId;

async function dormIdByName(name) {
  const [rows] = await db().query('SELECT id FROM dormitories WHERE name = ?', [name]);
  return rows[0] && rows[0].id;
}

beforeAll(async () => {
  ownerA = await A.newUser('owner');
  ownerB = await A.newUser('owner');
  student = await A.newUser('user');
});
afterAll(async () => {
  await cleanup();
  await close();
});

describe('Create a dorm', () => {
  test('OWN-01 owner creates a dorm with an image', async () => {
    const data = A.dormData();
    const res = await A.createDorm(ownerA.token, data);
    expect([200, 201]).toContain(res.status);
    dormId = A.idOf(res) || (await dormIdByName(data.name));
    expect(dormId).toBeTruthy();

    const [rows] = await db().query('SELECT * FROM dormitories WHERE id = ?', [dormId]);
    expect(rows[0].zone).toBe(data.zone);
    expect(Number(rows[0].latitude)).toBeCloseTo(data.latitude, 4);
    expect(Number(rows[0].longitude)).toBeCloseTo(data.longitude, 4);
    expect(rows[0].cover_image).toBeTruthy();
  });

  test('OWN-02 the new dorm shows in the owner\'s list', async () => {
    const res = await A.auth(A.call(A.EP.owner.listDorms), ownerA.token);
    expect(res.status).toBe(200);
    expect(A.listOf(res).map((d) => Number(d.id))).toContain(Number(dormId));
  });

  test('OWN-03 missing name is rejected', async () => {
    const { name, ...rest } = A.dormData();
    const res = await A.createDorm(ownerA.token, rest);
    expect(res.status).toBe(400);
  });

  test('OWN-04 a zone not in the list is rejected', async () => {
    const res = await A.createDorm(ownerA.token, A.dormData({ zone: 'กรุงเทพ' }));
    expect(res.status).toBe(400);
  });

  test('OWN-05 out-of-range coordinates are rejected', async () => {
    const res = await A.createDorm(ownerA.token, A.dormData({ latitude: 200, longitude: 500 }));
    expect(res.status).toBe(400);
  });

  test('OWN-06 negative or non-numeric price is rejected', async () => {
    const r1 = await A.createDorm(ownerA.token, A.dormData({ price: -100 }));
    const r2 = await A.createDorm(ownerA.token, A.dormData({ price: 'free' }));
    expect(r1.status).toBe(400);
    expect(r2.status).toBe(400);
  });

  test('OWN-07 uploading a non-image file is rejected', async () => {
    const res = await A.createDorm(ownerA.token, A.dormData(), 'not-image.txt');
    expect([400, 415]).toContain(res.status);
  });
});

describe('Edit / delete and permissions', () => {
  test('OWN-08 owner edits the price of their own dorm', async () => {
    const res = await A.auth(A.call(A.EP.owner.updateDorm, { id: dormId }), ownerA.token).send({ price: 4200 });
    expect(res.status).toBe(200);
    const [rows] = await db().query('SELECT price FROM dormitories WHERE id = ?', [dormId]);
    expect(Number(rows[0].price)).toBe(4200);
  });

  test('OWN-09 another owner cannot edit this dorm', async () => {
    const res = await A.auth(A.call(A.EP.owner.updateDorm, { id: dormId }), ownerB.token).send({ price: 1 });
    expect([403, 404]).toContain(res.status);
    const [rows] = await db().query('SELECT price FROM dormitories WHERE id = ?', [dormId]);
    expect(Number(rows[0].price)).toBe(4200);
  });

  test('OWN-10 another owner cannot delete this dorm', async () => {
    const res = await A.auth(A.call(A.EP.owner.deleteDorm, { id: dormId }), ownerB.token);
    expect([403, 404]).toContain(res.status);
    const [rows] = await db().query('SELECT id FROM dormitories WHERE id = ?', [dormId]);
    expect(rows.length).toBe(1);
  });

  test('OWN-11 a student cannot create a dorm', async () => {
    const res = await A.createDorm(student.token, A.dormData());
    expect(res.status).toBe(403);
  });

  test('OWN-12 creating a dorm without a token returns 401', async () => {
    const res = await A.createDorm(null, A.dormData());
    expect(res.status).toBe(401);
  });

  test('OWN-13 owner deletes their own dorm', async () => {
    const res = await A.auth(A.call(A.EP.owner.deleteDorm, { id: dormId }), ownerA.token);
    expect([200, 204]).toContain(res.status);
    const [rows] = await db().query('SELECT id FROM dormitories WHERE id = ?', [dormId]);
    expect(rows.length).toBe(0);
  });
});

describe('Submit verification', () => {
  test('OWN-14 owner submits an ownership document and gets status pending', async () => {
    const res = await A.submitVerification(ownerA.token);
    expect([200, 201]).toContain(res.status);
    const [rows] = await db().query(
      'SELECT v.status, v.document_url FROM verifications v JOIN users u ON u.id = v.owner_id WHERE u.username = ?',
      [ownerA.username]
    );
    expect(rows.length).toBeGreaterThan(0);
    expect(rows[0].status).toBe('pending');
    expect(rows[0].document_url).toBeTruthy();
  });

  test('OWN-15 a student cannot submit a verification', async () => {
    const res = await A.submitVerification(student.token);
    expect(res.status).toBe(403);
  });
});
