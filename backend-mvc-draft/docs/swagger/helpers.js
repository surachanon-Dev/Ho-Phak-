// ตัวช่วยสร้าง OpenAPI spec ให้ path แต่ละตัวสั้นและสม่ำเสมอ
// ไฟล์นี้มีแค่ "รูปแบบ" ของ spec ไม่มีการเรียก DB หรือแก้ข้อมูลใด ๆ

const ref = (name) => ({ $ref: `#/components/schemas/${name}` });

// response ที่ใช้ซ้ำบ่อย
const errorContent = { 'application/json': { schema: ref('Error') } };
const COMMON_RESPONSES = {
    400: { description: 'ข้อมูลที่ส่งมาไม่ถูกต้อง', content: errorContent },
    401: { description: 'ไม่มี token, token ผิด หรือหมดอายุ', content: errorContent },
    403: { description: 'ไม่มีสิทธิ์ (role ไม่ตรง, ยังไม่ยืนยันตัวตน หรือบัญชี/หอถูกระงับ)', content: errorContent },
    404: { description: 'ไม่พบข้อมูล หรือไม่ใช่ของผู้ใช้คนนี้', content: errorContent },
    409: { description: 'ข้อมูลซ้ำหรือสถานะไม่เปิดให้ทำแบบนี้', content: errorContent },
};

// สร้าง operation หนึ่งตัว
// secure: true = ต้องส่ง Bearer token (ปุ่ม Authorize ใน Swagger)
// body: { schema, multipart } ถ้า multipart เป็น true จะส่งเป็น form-data (อัปโหลดไฟล์)
// responses: เพิ่มเฉพาะ code ที่สำเร็จ ส่วน error ทั่วไปจะเติมให้อัตโนมัติตาม secure/parameters
function op({ tag, summary, description, secure = false, parameters = [], body, responses, errors }) {
    const allResponses = { ...(responses || {}) };
    const errorCodes = errors || [];
    for (const code of errorCodes) {
        if (COMMON_RESPONSES[code]) allResponses[code] = COMMON_RESPONSES[code];
    }
    if (secure && !allResponses[401]) allResponses[401] = COMMON_RESPONSES[401];
    if (secure && !allResponses[403]) allResponses[403] = COMMON_RESPONSES[403];

    const operation = {
        tags: [tag],
        summary,
        description,
        parameters,
        responses: allResponses,
    };
    if (secure) operation.security = [{ bearerAuth: [] }];
    if (body) {
        operation.requestBody = {
            required: true,
            content: {
                [body.multipart ? 'multipart/form-data' : 'application/json']: { schema: body.schema },
            },
        };
    }
    return operation;
}

// response สำเร็จแบบ JSON
const ok = (description, schema) => ({
    description,
    content: { 'application/json': { schema } },
});

// ตัวแปรใน path
const pathParam = (name, description = 'id', type = 'integer') => ({
    name, in: 'path', required: true, description, schema: type === 'integer' ? { type: 'integer', minimum: 1 } : { type },
});

// query string
const queryParam = (name, description, schema = { type: 'string' }) => ({
    name, in: 'query', required: false, description, schema,
});

// รวม path หลายไฟล์เข้าด้วยกัน
// path เดียวกันอาจมีหลาย method (เช่น GET ใช้ได้ทุกคน, POST ใช้ได้เฉพาะ student)
// จึงต้อง merge ระดับ method ไม่ใช่ทับทั้ง path
function mergePaths(...groups) {
    const result = {};
    for (const group of groups) {
        for (const [route, methods] of Object.entries(group)) {
            result[route] = { ...(result[route] || {}), ...methods };
        }
    }
    return result;
}

module.exports = { ref, op, ok, pathParam, queryParam, mergePaths, COMMON_RESPONSES };
