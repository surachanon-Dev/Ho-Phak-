// endpoint ของ role owner (เจ้าของหอ)
// หลายรายการต้องเป็น owner ที่ is_verified = 1 เท่านั้น (ระบุในคำอธิบายของแต่ละ endpoint)
const { ref, op, ok, pathParam } = require('./helpers');

const TAG = 'เจ้าของหอ (owner)';
const VERIFIED_NOTE = 'ต้องเป็น owner ที่ยืนยันตัวตนแล้ว (is_verified = 1) ไม่เช่นนั้นจะได้ 403';

const documentBody = {
    multipart: true,
    schema: {
        type: 'object',
        required: ['document'],
        properties: {
            document: { type: 'string', format: 'binary', description: 'ไฟล์ pdf, jpg หรือ png ไม่เกิน 10 MB' },
        },
    },
};

const imagesBody = {
    multipart: true,
    schema: {
        type: 'object',
        required: ['images'],
        properties: {
            images: {
                type: 'array',
                items: { type: 'string', format: 'binary' },
                description: 'รูปหอ jpg, png หรือ webp สูงสุด 5 ไฟล์ ไฟล์ละไม่เกิน 5 MB',
            },
        },
    },
};

const paths = {
    '/api/owner/verification': {
        get: op({
            tag: TAG,
            summary: 'ดูสถานะการยืนยันตัวตนของฉัน',
            description: 'ใช้ได้แม้ยังไม่ยืนยัน เพื่อดูว่าเอกสารอยู่ในสถานะไหน',
            secure: true,
            responses: {
                200: ok('สถานะการยืนยัน (null ถ้ายังไม่เคยส่ง)', {
                    type: 'object',
                    properties: { verification: { type: 'object', nullable: true } },
                }),
            },
        }),
        post: op({
            tag: TAG,
            summary: 'ส่งเอกสารยืนยันตัวตน',
            description: 'ใช้ได้แม้ยังไม่ยืนยัน เอกสารเก็บเป็นส่วนตัว admin เท่านั้นที่ดูได้',
            secure: true,
            body: documentBody,
            responses: { 201: ok('ส่งเอกสารแล้ว', ref('Message')) },
            errors: [400],
        }),
    },

    '/api/owner/dormitories': {
        get: op({
            tag: TAG,
            summary: 'รายการหอของฉันทั้งหมด',
            description: `${VERIFIED_NOTE} รวมหอที่ยังรอตรวจและถูกปฏิเสธด้วย`,
            secure: true,
            responses: {
                200: ok('รายการหอ', {
                    type: 'object',
                    properties: { dormitories: { type: 'array', items: { type: 'object' } } },
                }),
            },
        }),
        post: op({
            tag: TAG,
            summary: 'เพิ่มหอพักใหม่',
            description: `${VERIFIED_NOTE} หอใหม่จะรอ admin อนุมัติก่อนแสดงให้นักศึกษาเห็น`,
            secure: true,
            body: { schema: ref('DormitoryInput') },
            responses: { 201: ok('ส่งหอให้ admin ตรวจแล้ว', { type: 'object', properties: { message: { type: 'string' }, id: { type: 'integer' } } }) },
            errors: [400],
        }),
    },

    '/api/owner/dormitories/{id}': {
        get: op({
            tag: TAG,
            summary: 'ดูหอของฉัน',
            description: `${VERIFIED_NOTE} ดูได้เฉพาะหอของตัวเอง ของคนอื่นได้ 404`,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: {
                200: ok('ข้อมูลหอ', { type: 'object', properties: { dormitory: { type: 'object' } } }),
            },
            errors: [404],
        }),
        put: op({
            tag: TAG,
            summary: 'แก้ไขหอของฉัน',
            description: `${VERIFIED_NOTE} ถ้าหอเผยแพร่แล้ว การแก้ไขจะรอ admin ตรวจอีกครั้ง ส่วนหอที่ถูกระงับแก้ไม่ได้`,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            body: { schema: ref('DormitoryInput') },
            responses: { 200: ok('แก้ไขแล้ว', { type: 'object', properties: { message: { type: 'string' } } }) },
            errors: [400, 403, 404],
        }),
    },

    '/api/owner/dormitories/{id}/visibility': {
        patch: op({
            tag: TAG,
            summary: 'สลับการแสดงผลหอ (แสดง / ซ่อน)',
            description: `${VERIFIED_NOTE} สลับได้เฉพาะหอที่สถานะเป็น published หรือ hidden ถ้าเป็นสถานะอื่นจะได้ 409`,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: {
                200: ok('เปลี่ยนแล้ว', {
                    type: 'object',
                    properties: {
                        message: { type: 'string' },
                        status: { type: 'string', enum: ['published', 'hidden'] },
                    },
                }),
            },
            errors: [403, 404, 409],
        }),
    },

    '/api/owner/dormitories/{id}/reviews': {
        get: op({
            tag: TAG,
            summary: 'ดูรีวิวของหอฉัน',
            description: VERIFIED_NOTE,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            responses: { 200: ok('รีวิวของหอ', { type: 'object' }) },
            errors: [404],
        }),
    },

    '/api/owner/dormitories/{id}/images': {
        post: op({
            tag: TAG,
            summary: 'อัปโหลดรูปหอพัก',
            description: `${VERIFIED_NOTE} อัปโหลดได้เฉพาะหอของตัวเอง`,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            body: imagesBody,
            responses: {
                201: ok('อัปโหลดแล้ว', {
                    type: 'object',
                    properties: { message: { type: 'string' }, count: { type: 'integer' } },
                }),
            },
            errors: [400, 403, 404],
        }),
    },

    '/api/owner/dormitories/{id}/images/{imageId}': {
        delete: op({
            tag: TAG,
            summary: 'ลบรูปหอพัก',
            description: VERIFIED_NOTE,
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก'), pathParam('imageId', 'id ของรูป')],
            responses: { 200: ok('ลบแล้ว', ref('Message')) },
            errors: [403, 404],
        }),
    },
};

module.exports = { paths, TAG };
