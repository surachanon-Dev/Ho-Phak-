// schema ของข้อมูลที่ใช้ร่วมกันในทุก role (ใช้ใน components.schemas)

const schemas = {
    Error: {
        type: 'object',
        properties: { message: { type: 'string', example: 'ไม่มีสิทธิ์เข้าถึง' } },
    },

    LoginRequest: {
        type: 'object',
        required: ['phone', 'password'],
        properties: {
            phone: { type: 'string', example: '0812345678', description: 'เบอร์มือถือไทย 10 หลัก รองรับ +66' },
            password: { type: 'string', example: 'password123' },
        },
    },

    LoginResponse: {
        type: 'object',
        properties: {
            message: { type: 'string', example: 'Login success' },
            token: { type: 'string', description: 'ใช้ใส่ปุ่ม Authorize' },
            user: {
                type: 'object',
                properties: {
                    id: { type: 'integer', example: 1 },
                    role: { type: 'string', enum: ['student', 'owner', 'admin'] },
                    is_verified: { type: 'integer', enum: [0, 1], description: 'owner ต้องเป็น 1 จึงจัดการหอได้' },
                },
            },
        },
    },

    RegisterRequest: {
        type: 'object',
        required: ['phone', 'password'],
        properties: {
            phone: { type: 'string', example: '0899999999' },
            password: { type: 'string', minLength: 8, example: 'password123' },
            confirmPassword: { type: 'string', example: 'password123', description: 'ถ้าส่งมาต้องตรงกับ password' },
            username: { type: 'string', maxLength: 50, example: 'student01' },
        },
        description: 'role ถูกกำหนดเป็น student เสมอ ส่ง role มาก็ไม่มีผล',
    },

    CurrentUser: {
        type: 'object',
        properties: {
            user: {
                type: 'object',
                properties: {
                    id: { type: 'integer' },
                    username: { type: 'string', nullable: true },
                    role: { type: 'string', enum: ['student', 'owner', 'admin'] },
                    status: { type: 'string', enum: ['active', 'suspended'] },
                    is_verified: { type: 'integer', enum: [0, 1] },
                },
            },
        },
    },

    Message: {
        type: 'object',
        description: 'ข้อความใช้ตอบกลับ id เท่านั้น',
        properties: { message: { type: 'string' } },
    },

    DormitoryInput: {
        type: 'object',
        description: 'ใช้ทั้ง POST (สร้าง) และ PUT (แก้ไข) ค่าที่ไม่มีใน water/electricity ให้ส่งทั้งคู่หรือไม่ส่งเลย',
        required: [
            'name', 'zone', 'latitude', 'longitude', 'price_per_month', 'total_rooms', 'available_rooms',
        ],
        properties: {
            name: { type: 'string', maxLength: 100, example: 'หอทดสอบ' },
            zone: { type: 'string', enum: ['หน้ามอ', 'หลังมอ', 'คชพลแลนด์'] },
            latitude: { type: 'number', minimum: -90, maximum: 90, example: 19.8807 },
            longitude: { type: 'number', minimum: -180, maximum: 180, example: 99.8325 },
            price_per_month: { type: 'integer', minimum: 1, maximum: 1000000, example: 3500 },
            total_rooms: { type: 'integer', minimum: 0, example: 10 },
            available_rooms: { type: 'integer', minimum: 0, example: 3, description: 'ต้องไม่เกิน total_rooms' },
            water_rate: { type: 'number', minimum: 0, example: 18, description: 'ทศนิยมไม่เกิน 2 ตำแหน่ง' },
            water_billing_type: { type: 'string', enum: ['per_unit', 'per_person_month', 'per_room_month'] },
            electricity_rate: { type: 'number', minimum: 0, example: 8 },
            electricity_billing_type: { type: 'string', enum: ['per_unit', 'per_person_month', 'per_room_month'] },
            description: { type: 'string', maxLength: 2000 },
            address: { type: 'string', maxLength: 1000 },
            contact_phone: { type: 'string', example: '0812345678' },
            amenity_ids: { type: 'array', items: { type: 'integer' }, example: [1, 2] },
        },
    },

    ReviewInput: {
        type: 'object',
        required: ['rating'],
        properties: {
            rating: { type: 'integer', minimum: 1, maximum: 5, example: 4 },
            body: { type: 'string', maxLength: 1000, example: 'ห้องสะอาด น้ำแรงดี' },
        },
    },

    ChatOpenRequest: {
        type: 'object',
        required: ['dormitory_id'],
        properties: {
            dormitory_id: { type: 'integer', example: 1, description: 'เจ้าของหอดึงจากฐานข้อมูลเอง ไม่ต้องส่ง owner_id' },
        },
    },

    MessageInput: {
        type: 'object',
        required: ['body'],
        properties: {
            body: { type: 'string', minLength: 1, maxLength: 2000, example: 'สวัสดีครับ ยังมีห้องว่างไหม' },
        },
    },

    ReasonInput: {
        type: 'object',
        properties: {
            reason: { type: 'string', example: 'ข้อมูลไม่ครบ' },
        },
        description: 'เหตุผลไม่บังคับ ใส่หรือไม่ใส่ก็ได้',
    },
};

module.exports = { schemas };
