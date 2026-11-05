/**
 * Unit Test: argon2id hashing (follows the spec: Username/password hashed by argon2id)
 */
const { hash, verify } = require('@node-rs/argon2'); // same library as the Backend
const { db, close } = require('../helpers/db');

afterAll(close);

test('UNIT-05 argon2id hash has the right format and fits varchar(97)', async () => {
  const h = await hash('Passw0rd!');
  expect(h.startsWith('$argon2id$')).toBe(true);
  expect(h.length).toBeLessThanOrEqual(97);
});

test('UNIT-06 the correct password passes, a wrong one fails', async () => {
  const h = await hash('Passw0rd!');
  expect(await verify(h, 'Passw0rd!')).toBe(true);
  expect(await verify(h, 'passw0rd!')).toBe(false);
});

test('UNIT-07 the same password hashed twice gives different hashes (salted)', async () => {
  const a = await hash('same');
  const b = await hash('same');
  expect(a).not.toBe(b);
});

test('UNIT-08 every user in the DB has an argon2id hash (no plaintext)', async () => {
  const [rows] = await db().query('SELECT username, password FROM users');
  const bad = rows.filter((r) => !String(r.password).startsWith('$argon2id$')).map((r) => r.username);
  expect(bad).toEqual([]);
});
