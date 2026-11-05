/**
 * API Test: Authentication (Register / Login / Logout / JWT / Role)
 * The test IDs (AUTH-xx) match the table in the Test Plan doc.
 */
const jwt = require('jsonwebtoken');
const A = require('../helpers/api');
const { db, cleanup, close } = require('../helpers/db');

afterAll(async () => {
  await cleanup();
  await close();
});

describe('Register', () => {
  test('AUTH-01 sign up as user (student) succeeds', async () => {
    const { res } = await A.register({ role: 'user' });
    expect([200, 201]).toContain(res.status);
  });

  test('AUTH-02 sign up as owner succeeds', async () => {
    const { res } = await A.register({ role: 'owner' });
    expect([200, 201]).toContain(res.status);
  });

  test('AUTH-03 duplicate username is rejected', async () => {
    const first = await A.register();
    const { res } = await A.register({ username: first.username });
    expect([400, 409]).toContain(res.status);
  });

  test('AUTH-04 missing username or password is rejected', async () => {
    const r1 = await A.call(A.EP.auth.register).send({ password: 'Passw0rd!' });
    const r2 = await A.call(A.EP.auth.register).send({ username: A.uniqueName() });
    expect(r1.status).toBe(400);
    expect(r2.status).toBe(400);
  });

  test('AUTH-05 cannot sign up as admin yourself', async () => {
    const u = await A.register({ role: 'admin' });
    if ([200, 201].includes(u.res.status)) {
      // If the server accepts it, the saved role must not be admin
      const [rows] = await db().query('SELECT role FROM users WHERE username = ?', [u.username]);
      expect(rows[0].role).not.toBe('admin');
    } else {
      expect([400, 403]).toContain(u.res.status);
    }
  });

  test('AUTH-06 password is stored as argon2id, not plaintext', async () => {
    const u = await A.register();
    const [rows] = await db().query('SELECT password FROM users WHERE username = ?', [u.username]);
    expect(rows[0].password).not.toBe(u.password);
    expect(rows[0].password.startsWith('$argon2id$')).toBe(true);
  });
});

describe('Login / JWT', () => {
  let user;
  beforeAll(async () => {
    user = await A.register({ role: 'owner' });
  });

  test('AUTH-07 correct username and password return a token', async () => {
    const { res, token } = await A.login(user.username, user.password);
    expect(res.status).toBe(200);
    expect(typeof token).toBe('string');
  });

  test('AUTH-08 wrong password returns 401', async () => {
    const { res, token } = await A.login(user.username, 'wrong-pass');
    expect(res.status).toBe(401);
    expect(token).toBeUndefined();
  });

  test('AUTH-09 unknown username returns 401 with the same message as a wrong password', async () => {
    const wrongPw = await A.login(user.username, 'wrong-pass');
    const noUser = await A.login(A.uniqueName('ghost'), 'whatever');
    expect(noUser.res.status).toBe(401);
    // So nobody can guess which usernames exist
    expect(JSON.stringify(noUser.res.body)).toBe(JSON.stringify(wrongPw.res.body));
  });

  test('AUTH-10 JWT has role and expiry, and no password', async () => {
    const { token } = await A.login(user.username, user.password);
    const payload = jwt.decode(token);
    expect(payload).toBeTruthy();
    expect(payload.role).toBe('owner');
    expect(payload.exp).toBeGreaterThan(Math.floor(Date.now() / 1000));
    expect(JSON.stringify(payload)).not.toMatch(/password|argon2/i);
  });

  test('AUTH-11 protected route without a token returns 401', async () => {
    const res = await A.call(A.EP.owner.listDorms);
    expect(res.status).toBe(401);
  });

  test('AUTH-12 forged token returns 401', async () => {
    const fake = jwt.sign({ id: 1, role: 'admin' }, 'not-the-real-secret');
    const res = await A.auth(A.call(A.EP.admin.listVerifications), fake);
    expect(res.status).toBe(401);
  });

  test('AUTH-13 logout succeeds', async () => {
    const { token } = await A.login(user.username, user.password);
    const res = await A.auth(A.call(A.EP.auth.logout), token);
    expect([200, 204]).toContain(res.status);
  });

  test('AUTH-14 SQL injection in login does not get in', async () => {
    const { res, token } = await A.login("' OR '1'='1' -- ", "' OR '1'='1");
    expect([400, 401]).toContain(res.status);
    expect(token).toBeUndefined();
  });
});
