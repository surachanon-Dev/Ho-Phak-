// endpoint ที่ใช้ร่วมกัน: ไม่ต้อง login (สาธารณะ) และ endpoint ทั่วไปของผู้ที่ login แล้ว
// ทุก role จะเห็นกลุ่มนี้ใน Swagger ของตัวเอง
const { ref, op, ok, pathParam, queryParam } = require('./helpers');

const TAG_PUBLIC = 'ทั่วไป (ไม่ต้อง login)';
const TAG_AUTH = 'บัญชีและการเข้าสู่ระบบ';
const TAG_CHAT = 'แชท (student และ owner)';
const TAG_NOTI = 'การแจ้งเตือน';

const paths = {
    '/api/login': {
        post: op({
            tag: TAG_AUTH,
            summary: 'เข้าสู่ระบบ',
            description: 'login ด้วยเบอร์โทรและรหัสผ่าน แล้วคืน token (อายุ 1 วัน) ใช้ token นี้ใส่ปุ่ม Authorize',
            body: { schema: ref('LoginRequest') },
            responses: { 200: ok('login สำเร็จ', ref('LoginResponse')) },
            errors: [400, 401, 403],
        }),
    },

    '/api/auth/register': {
        post: op({
            tag: TAG_AUTH,
            summary: 'สมัครสมาชิก (student)',
            description: 'สมัครได้เฉพาะ student เท่านั้น บัญชี owner สร้างโดยผู้ดูแลระบบ',
            body: { schema: ref('RegisterRequest') },
            responses: {
                201: ok('สมัครสำเร็จ', {
                    type: 'object',
                    properties: { message: { type: 'string' }, id: { type: 'integer' } },
                }),
            },
            errors: [400, 409],
        }),
    },

    '/api/auth/logout': {
        post: op({
            tag: TAG_AUTH,
            summary: 'ออกจากระบบ',
            description: 'server ไม่ได้เก็บ session ฝั่ง client ต้องลบ token เอง',
            secure: true,
            responses: { 200: ok('ออกจากระบบแล้ว', ref('Message')) },
        }),
    },

    '/api/me': {
        get: op({
            tag: TAG_AUTH,
            summary: 'ดูข้อมูลผู้ที่ login อยู่',
            description: 'ใช้ตรวจว่า token ยังใช้ได้และดู role ของตัวเอง',
            secure: true,
            responses: { 200: ok('ข้อมูลผู้ใช้', ref('CurrentUser')) },
        }),
    },

    '/api/dormitories': {
        get: op({
            tag: TAG_PUBLIC,
            summary: 'ค้นหาหอพัก (แสดงเฉพาะหอที่เผยแพร่แล้ว)',
            parameters: [
                queryParam('zone', 'กรองตามโซน', { type: 'string', enum: ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'] }),
                queryParam('minPrice', 'ราคาต่ำสุดต่อเดือน', { type: 'integer' }),
                queryParam('maxPrice', 'ราคาสูงสุดต่อเดือน', { type: 'integer' }),
                queryParam('hasRooms', 'ส่ง 1 เพื่อดูเฉพาะหอที่ยังมีห้องว่าง', { type: 'string', enum: ['1'] }),
                queryParam('sort', 'เรียงลำดับ', { type: 'string', enum: ['newest', 'price_asc', 'price_desc'] }),
                queryParam('q', 'คำค้นหาชื่อหอ'),
            ],
            responses: {
                200: ok('รายการหอ', {
                    type: 'object',
                    properties: { dormitories: { type: 'array', items: { type: 'object' } } },
                }),
            },
            errors: [400],
        }),
    },

    '/api/dormitories/{id}': {
        get: op({
            tag: TAG_PUBLIC,
            summary: 'รายละเอียดหอพัก',
            description: 'คืนข้อมูลหอ สิ่งอำนวยความสะดวก รูปภาพ และสรุปคะแนนรีวิว',
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: {
                200: ok('รายละเอียดหอ', {
                    type: 'object',
                    properties: { dormitory: { type: 'object' } },
                }),
            },
            errors: [404],
        }),
    },

    '/api/dormitories/{id}/reviews': {
        get: op({
            tag: TAG_PUBLIC,
            summary: 'รีวิวที่เผยแพร่แล้วของหอพัก',
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: { 200: ok('รีวิวและคะแนนเฉลี่ย', { type: 'object' }) },
            errors: [404],
        }),
    },

    '/api/conversations': {
        get: op({
            tag: TAG_CHAT,
            summary: 'รายการแชทของฉัน',
            description: 'student เห็นแชทที่ตัวเองเปิด owner เห็นแชทของหอที่ตัวเองเป็นเจ้าของ',
            secure: true,
            responses: {
                200: ok('รายการแชท', {
                    type: 'object',
                    properties: { conversations: { type: 'array', items: { type: 'object' } } },
                }),
            },
            errors: [403],
        }),
    },

    '/api/conversations/{id}/messages': {
        get: op({
            tag: TAG_CHAT,
            summary: 'อ่านข้อความในแชท',
            description: 'ได้เฉพาะคู่สนทนา (student หรือ owner ของหอนั้น) ไม่ใช่ตอบ 404',
            secure: true,
            parameters: [pathParam('id', 'id ของแชท')],
            responses: {
                200: ok('ข้อความทั้งหมด', {
                    type: 'object',
                    properties: {
                        messages: { type: 'array', items: { type: 'object' } },
                        read_only: { type: 'boolean', description: 'true เมื่อหอถูกลบหรือถูกระงับ' },
                    },
                }),
            },
            errors: [403, 404],
        }),
        post: op({
            tag: TAG_CHAT,
            summary: 'ส่งข้อความ',
            description: 'ได้เฉพาะคู่สนทนา และส่งไม่ได้ถ้าหอถูกลบหรือถูกระงับ',
            secure: true,
            parameters: [pathParam('id', 'id ของแชท')],
            body: { schema: ref('MessageInput') },
            responses: {
                201: ok('ส่งแล้ว', { type: 'object', properties: { id: { type: 'integer' } } }),
            },
            errors: [400, 403, 404],
        }),
    },

    '/api/conversations/{id}': {
        delete: op({
            tag: TAG_CHAT,
            summary: 'ลบแชทออกจากรายการของตัวเอง',
            description: 'ลบเฉพาะฝั่งตัวเอง อีกฝ่ายยังเห็นแชทอยู่',
            secure: true,
            parameters: [pathParam('id', 'id ของแชท')],
            responses: { 200: ok('ลบแล้ว', ref('Message')) },
            errors: [403, 404],
        }),
    },

    '/api/notifications': {
        get: op({
            tag: TAG_NOTI,
            summary: 'รายการแจ้งเตือนของฉัน',
            secure: true,
            responses: {
                200: ok('รายการแจ้งเตือน', {
                    type: 'object',
                    properties: { notifications: { type: 'array', items: { type: 'object' } } },
                }),
            },
        }),
    },

    '/api/notifications/{id}/read': {
        patch: op({
            tag: TAG_NOTI,
            summary: 'ทำเครื่องหมายว่าอ่านแล้ว',
            secure: true,
            parameters: [pathParam('id', 'id ของการแจ้งเตือน')],
            responses: { 200: ok('อ่านแล้ว', ref('Message')) },
            errors: [404],
        }),
    },
};

module.exports = { paths, TAG_PUBLIC, TAG_AUTH, TAG_CHAT, TAG_NOTI };
