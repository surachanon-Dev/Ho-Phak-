// ประกอบ OpenAPI spec 3 ชุด แยกตาม role
// - /api-docs/student  : endpoint ทั่วไป + ของ student
// - /api-docs/owner    : endpoint ทั่วไป + ของ owner
// - /api-docs/admin    : endpoint ทั่วไป + ของ admin
// endpoint ทั่วไปคือ login/สมัคร, หอสาธารณะ, แชท และการแจ้งเตือน ทุก role ใช้ร่วมกัน
const { mergePaths } = require('./helpers');
const { schemas } = require('./schemas');
const common = require('./paths-common');
const student = require('./paths-student');
const owner = require('./paths-owner');
const admin = require('./paths-admin');

const SERVER_URL = process.env.SWAGGER_SERVER_URL || 'http://localhost:3000';

const components = {
    schemas,
    securitySchemes: {
        bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: 'วาง token จาก POST /api/login (ไม่ต้องพิมพ์คำว่า Bearer นำหน้า Swagger เติมให้)',
        },
    },
};

const ROLE_INFO = {
    student: {
        title: 'Ho-Phak API: นักศึกษา (student)',
        description: 'ทดสอบด้วยบัญชี role = student\n\nเข้าสู่ระบบด้วย `POST /api/login` แล้วคัดลอก token ไปกดปุ่ม **Authorize**',
        groups: [common, student],
        tags: [common.TAG_PUBLIC, common.TAG_AUTH, student.TAG, common.TAG_CHAT, common.TAG_NOTI],
    },
    owner: {
        title: 'Ho-Phak API: เจ้าของหอ (owner)',
        description: 'ทดสอบด้วยบัญชี role = owner\n\nหอพักและรูปหอ ต้องเป็น owner ที่ยืนยันตัวตนแล้ว (`is_verified = 1`) จึงจะเรียกได้\nถ้ายังไม่ยืนยัน ให้ส่งเอกสารที่ `POST /api/owner/verification` แล้วให้ admin อนุมัติก่อน',
        groups: [common, owner],
        tags: [common.TAG_PUBLIC, common.TAG_AUTH, owner.TAG, common.TAG_CHAT, common.TAG_NOTI],
    },
    admin: {
        title: 'Ho-Phak API: แอดมิน (admin)',
        description: 'ทดสอบด้วยบัญชี role = admin\n\nทุก endpoint ในกลุ่มนี้ต้องใช้ token ของ admin เท่านั้น',
        groups: [common, admin],
        tags: [common.TAG_PUBLIC, common.TAG_AUTH, admin.TAG, common.TAG_CHAT, common.TAG_NOTI],
    },
};

function buildSpec(role) {
    const info = ROLE_INFO[role];
    const paths = mergePaths(...info.groups.map((g) => g.paths));
    return {
        openapi: '3.0.3',
        info: { title: info.title, version: '1.0.0', description: info.description },
        servers: [{ url: SERVER_URL }],
        tags: info.tags.map((name) => ({ name })),
        components,
        paths,
    };
}

const specs = {
    student: buildSpec('student'),
    owner: buildSpec('owner'),
    admin: buildSpec('admin'),
};

module.exports = { specs, ROLE_INFO };
