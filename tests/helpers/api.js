const path = require('path');
const request = require('supertest');
const EP = require('../config/endpoints');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const PREFIX = process.env.TEST_PREFIX || 'qa_';
const FIX = (name) => path.join(__dirname, '..', 'fixtures', name);

/** Read a value at "a.b.c" in an object */
function get(obj, p) {
  if (!p) return obj;
  return p.split('.').reduce((o, k) => (o == null ? undefined : o[k]), obj);
}
/** Try several paths and return the first one that has a value */
function pick(obj, paths) {
  for (const p of paths) {
    const v = get(obj, p);
    if (v !== undefined && v !== null) return v;
  }
  return undefined;
}
const tokenOf = (res) => pick(res.body, EP.fields.tokenPaths);
const idOf = (res) => pick(res.body, EP.fields.idPaths);
function listOf(res) {
  for (const p of EP.fields.listPaths) {
    const v = get(res.body, p);
    if (Array.isArray(v)) return v;
  }
  return [];
}

/** Build a request from 'METHOD /path/:id' */
function call(endpoint, params = {}) {
  const [method, rawPath] = endpoint.split(' ');
  const url = rawPath.replace(/:(\w+)/g, (_, k) => encodeURIComponent(params[k]));
  return request(BASE_URL)[method.toLowerCase()](url);
}
const auth = (req, token) => (token ? req.set('Authorization', `Bearer ${token}`) : req);

let counter = 0;
const uniqueName = (tag = 'u') =>
  `${PREFIX}${tag}_${Date.now().toString(36)}${(counter++).toString(36)}`;

async function register({ username, password = 'Passw0rd!', role = 'user' } = {}) {
  username = username || uniqueName(role);
  const res = await call(EP.auth.register).send({ username, password, role });
  return { res, username, password, role };
}
async function login(username, password) {
  const res = await call(EP.auth.login).send({ username, password });
  return { res, token: tokenOf(res) };
}
/** Register then log in; returns a ready-to-use token */
async function newUser(role = 'user') {
  const u = await register({ role });
  const { token, res } = await login(u.username, u.password);
  if (!token) {
    throw new Error(
      `Could not log in as ${role} (register=${u.res.status}, login=${res.status}). ` +
        `Check endpoints.js or whether the server is running at ${BASE_URL}`
    );
  }
  return { ...u, token };
}
async function adminToken() {
  const { token, res } = await login(process.env.ADMIN_USERNAME, process.env.ADMIN_PASSWORD);
  if (!token) throw new Error(`Admin login failed (${res.status}). Run "npm run seed" first`);
  return token;
}

/** Sample dorm data; override any field with extra */
function dormData(extra = {}) {
  return {
    name: `${PREFIX}หอทดสอบ ${Date.now()}`,
    zone: EP.zones[0],
    latitude: 16.4419,
    longitude: 102.8160,
    price: 3500,
    ...extra,
  };
}
/** Create a dorm as multipart (with an image) */
function createDorm(token, data = dormData(), image = 'dorm.png') {
  let req = auth(call(EP.owner.createDorm), token);
  for (const [k, v] of Object.entries(data)) req = req.field(k, String(v));
  if (image) req = req.attach(EP.fields.dormImage, FIX(image));
  return req;
}
function submitVerification(token, file = 'ownership-doc.pdf') {
  return auth(call(EP.owner.submitVerification), token).attach(EP.fields.verificationDoc, FIX(file));
}

module.exports = {
  EP, BASE_URL, PREFIX, FIX,
  call, auth, get, pick, tokenOf, idOf, listOf,
  uniqueName, register, login, newUser, adminToken,
  dormData, createDorm, submitVerification,
};
