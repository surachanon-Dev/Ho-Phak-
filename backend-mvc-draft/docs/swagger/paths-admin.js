// endpoint ของ role admin (ผู้ดูแลระบบ)
// ทุก endpoint ต้อง login ด้วยบัญชี role = admin และบัญชีต้อง active
const { ref, op, ok, pathParam, queryParam } = require('./helpers');

const TAG = 'แอดมิน (admin)';

const paths = {
    '/api/admin/queue': {
        get: op({
            tag: TAG,
            summary: 'คิวรอตรวจ',
            description: 'รวมหอที่รออนุมัติ การแก้ไขที่รอตรวจ เอกสารยืนยันตัวตน และรีวิวที่รอเผยแพร่',
            secure: true,
            responses: { 200: ok('รายการคิวรอตรวจ', { type: 'object' }) },
        }),
    },

    '/api/admin/logs': {
        get: op({
            tag: TAG,
            summary: 'บันทึกการกระทำของ admin',
            secure: true,
            responses: {
                200: ok('บันทึกทั้งหมด', {
                    type: 'object',
                    properties: { logs: { type: 'array', items: { type: 'object' } } },
                }),
            },
        }),
    },

    '/api/admin/dormitories': {
        get: op({
            tag: TAG,
            summary: 'รายการหอทั้งหมด (สำหรับ moderation)',
            secure: true,
            parameters: [
                queryParam('status', 'กรองตามสถานะหอ', {
                    type: 'string',
                    enum: ['pending', 'published', 'changes_pending', 'rejected', 'hidden', 'suspended'],
                }),
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

    '/api/admin/users': {
        get: op({
            tag: TAG,
            summary: 'รายการผู้ใช้ทั้งหมด',
            secure: true,
            parameters: [
                queryParam('role', 'กรองตาม role', { type: 'string', enum: ['student', 'owner', 'admin'] }),
                queryParam('status', 'กรองตามสถานะบัญชี', { type: 'string', enum: ['active', 'suspended'] }),
            ],
            responses: {
                200: ok('รายการผู้ใช้', {
                    type: 'object',
                    properties: { users: { type: 'array', items: { type: 'object' } } },
                }),
            },
            errors: [400],
        }),
    },

    '/api/admin/dormitories/{id}/approve': {
        post: op({
            tag: TAG,
            summary: 'อนุมัติหอพัก',
            description: 'ใช้กับหอที่รออนุมัติ หรือการแก้ไขที่รอตรวจ ระบบบันทึก admin_logs ให้อัตโนมัติ',
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: { 200: ok('อนุมัติแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/dormitories/{id}/reject': {
        post: op({
            tag: TAG,
            summary: 'ปฏิเสธหอพัก',
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            body: { schema: ref('ReasonInput') },
            responses: { 200: ok('ปฏิเสธแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/dormitories/{id}/suspend': {
        post: op({
            tag: TAG,
            summary: 'ระงับหอพัก',
            description: 'หอที่ถูกระงับนักศึกษาจะมองไม่เห็น และเจ้าของแก้ไขไม่ได้',
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            body: { schema: ref('ReasonInput') },
            responses: { 200: ok('ระงับแล้ว', ref('Message')) },
            errors: [404],
        }),
    },

    '/api/admin/dormitories/{id}/restore': {
        post: op({
            tag: TAG,
            summary: 'คืนสถานะหอที่ถูกระงับ',
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: { 200: ok('คืนสถานะแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/verifications/{id}/document': {
        get: op({
            tag: TAG,
            summary: 'ดูไฟล์เอกสารยืนยันตัวตน',
            description: 'ไฟล์เก็บเป็นส่วนตัว ดูได้เฉพาะผ่าน endpoint นี้ ผลลัพธ์เป็นไฟล์ที่ผู้ดูแลเปิดดูได้',
            secure: true,
            parameters: [pathParam('id', 'id ของคำขอยืนยันตัวตน')],
            responses: {
                200: {
                    description: 'ไฟล์เอกสาร (pdf / jpg / png)',
                    content: {
                        'application/pdf': { schema: { type: 'string', format: 'binary' } },
                        'image/jpeg': { schema: { type: 'string', format: 'binary' } },
                        'image/png': { schema: { type: 'string', format: 'binary' } },
                    },
                },
            },
            errors: [404],
        }),
    },

    '/api/admin/verifications/{id}/approve': {
        post: op({
            tag: TAG,
            summary: 'อนุมัติการยืนยันตัวตนเจ้าของหอ',
            description: 'เมื่ออนุมัติ บัญชีเจ้าของจะเป็น is_verified = 1 และจัดการหอได้',
            secure: true,
            parameters: [pathParam('id', 'id ของคำขอยืนยันตัวตน')],
            responses: { 200: ok('อนุมัติแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/verifications/{id}/reject': {
        post: op({
            tag: TAG,
            summary: 'ปฏิเสธการยืนยันตัวตนเจ้าของหอ',
            secure: true,
            parameters: [pathParam('id', 'id ของคำขอยืนยันตัวตน')],
            body: { schema: ref('ReasonInput') },
            responses: { 200: ok('ปฏิเสธแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/users/{id}/suspend': {
        post: op({
            tag: TAG,
            summary: 'ระงับบัญชีผู้ใช้',
            description: 'ระงับบัญชี admin ไม่ได้ ผลคือ token เดิมจะใช้ไม่ได้ทันที',
            secure: true,
            parameters: [pathParam('id', 'id ของผู้ใช้')],
            body: { schema: ref('ReasonInput') },
            responses: { 200: ok('ระงับแล้ว', ref('Message')) },
            errors: [403, 404],
        }),
    },

    '/api/admin/users/{id}/restore': {
        post: op({
            tag: TAG,
            summary: 'คืนสถานะบัญชีที่ถูกระงับ',
            secure: true,
            parameters: [pathParam('id', 'id ของผู้ใช้')],
            responses: { 200: ok('คืนสถานะแล้ว', ref('Message')) },
            errors: [404, 409],
        }),
    },

    '/api/admin/reviews': {
        get: op({
            tag: TAG,
            summary: 'รายการรีวิวตามสถานะ',
            secure: true,
            parameters: [
                queryParam('status', 'ค่าเริ่มต้นคือ pending', { type: 'string', enum: ['pending', 'published', 'hidden'] }),
            ],
            responses: {
                200: ok('รายการรีวิว', {
                    type: 'object',
                    properties: { reviews: { type: 'array', items: { type: 'object' } } },
                }),
            },
        }),
    },

    '/api/admin/reviews/{id}/publish': {
        post: op({
            tag: TAG,
            summary: 'เผยแพร่รีวิว',
            secure: true,
            parameters: [pathParam('id', 'id ของรีวิว')],
            responses: { 200: ok('เผยแพร่แล้ว', ref('Message')) },
            errors: [404],
        }),
    },

    '/api/admin/reviews/{id}/hide': {
        post: op({
            tag: TAG,
            summary: 'ซ่อนรีวิว',
            secure: true,
            parameters: [pathParam('id', 'id ของรีวิว')],
            body: { schema: ref('ReasonInput') },
            responses: { 200: ok('ซ่อนแล้ว', ref('Message')) },
            errors: [404],
        }),
    },
};

module.exports = { paths, TAG };
