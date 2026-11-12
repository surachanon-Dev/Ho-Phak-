// endpoint ของ role student (นักศึกษา)
// ต้อง login ด้วยบัญชี role = student เท่านั้น
const { ref, op, ok, pathParam } = require('./helpers');

const TAG = 'นักศึกษา (student)';

const paths = {
    '/api/dormitories/{id}/reviews': {
        post: op({
            tag: TAG,
            summary: 'เขียนรีวิวหอพัก',
            description: 'ส่งแล้วต้องรอ admin ตรวจก่อนแสดง และรีวิวได้เพียงครั้งเดียวต่อหอ',
            secure: true,
            parameters: [pathParam('id', 'id ของหอพัก')],
            body: { schema: ref('ReviewInput') },
            responses: {
                201: ok('ส่งรีวิวแล้ว รอตรวจสอบ', { type: 'object', properties: { message: { type: 'string' }, id: { type: 'integer' } } }),
            },
            errors: [400, 404, 409],
        }),
    },

    '/api/reviews/{id}': {
        put: op({
            tag: TAG,
            summary: 'แก้ไขรีวิวของตัวเอง',
            description: 'แก้แล้วกลับไปรอ admin ตรวจอีกครั้ง',
            secure: true,
            parameters: [pathParam('id', 'id ของรีวิว')],
            body: { schema: ref('ReviewInput') },
            responses: { 200: ok('แก้ไขแล้ว', ref('Message')) },
            errors: [400, 404],
        }),
        delete: op({
            tag: TAG,
            summary: 'ลบรีวิวของตัวเอง',
            secure: true,
            parameters: [pathParam('id', 'id ของรีวิว')],
            responses: { 200: ok('ลบแล้ว', ref('Message')) },
            errors: [404],
        }),
    },

    '/api/favorites': {
        get: op({
            tag: TAG,
            summary: 'รายการหอที่บันทึกไว้',
            secure: true,
            responses: {
                200: ok('รายการโปรด', {
                    type: 'object',
                    properties: { favorites: { type: 'array', items: { type: 'object' } } },
                }),
            },
        }),
    },

    '/api/favorites/{dormitoryId}': {
        post: op({
            tag: TAG,
            summary: 'เพิ่มหอในรายการโปรด',
            secure: true,
            parameters: [pathParam('dormitoryId', 'id ของหอพัก')],
            description: 'เพิ่มได้เฉพาะหอที่เผยแพร่แล้ว ถ้าเพิ่มซ้ำจะไม่เกิด error',
            responses: { 201: ok('เพิ่มแล้ว', ref('Message')) },
            errors: [404],
        }),
        delete: op({
            tag: TAG,
            summary: 'ลบหอออกจากรายการโปรด',
            secure: true,
            parameters: [pathParam('dormitoryId', 'id ของหอพัก')],
            responses: { 200: ok('ลบแล้ว', ref('Message')) },
            errors: [404],
        }),
    },

    '/api/conversations': {
        post: op({
            tag: TAG,
            summary: 'เปิดแชทกับเจ้าของหอ',
            description: 'ถ้าเคยเปิดแชทกับหอนี้แล้วจะคืนแชทเดิม (created = false)',
            secure: true,
            body: { schema: ref('ChatOpenRequest') },
            responses: {
                201: ok('เปิดแชทใหม่', { type: 'object', properties: { id: { type: 'integer' }, message: { type: 'string' } } }),
                200: ok('มีแชทเดิมอยู่แล้ว', { type: 'object', properties: { id: { type: 'integer' }, message: { type: 'string' } } }),
            },
            errors: [400, 403, 404],
        }),
    },
};

module.exports = { paths, TAG };
