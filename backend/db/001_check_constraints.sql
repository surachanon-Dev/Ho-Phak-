-- เพิ่ม CHECK constraint ที่หายไปจาก dump รุ่นล่าสุด
-- รันหลัง import dump แล้ว ทำซ้ำไม่ได้ถ้า constraint มีอยู่แล้ว

ALTER TABLE dormitories
  ADD CONSTRAINT chk_dormitories_available_rooms CHECK (available_rooms <= total_rooms),
  ADD CONSTRAINT chk_dormitories_water_rate CHECK (water_rate IS NULL OR water_rate >= 0),
  ADD CONSTRAINT chk_dormitories_electricity_rate CHECK (electricity_rate IS NULL OR electricity_rate >= 0),
  ADD CONSTRAINT chk_dormitories_water_billing_pair CHECK (
    (water_rate IS NULL AND water_billing_type IS NULL)
    OR (water_rate IS NOT NULL AND water_billing_type IS NOT NULL)
  ),
  ADD CONSTRAINT chk_dormitories_electricity_billing_pair CHECK (
    (electricity_rate IS NULL AND electricity_billing_type IS NULL)
    OR (electricity_rate IS NOT NULL AND electricity_billing_type IS NOT NULL)
  );

ALTER TABLE reviews
  ADD CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5),
  ADD CONSTRAINT chk_reviews_body CHECK (body IS NULL OR CHAR_LENGTH(TRIM(body)) > 0);

ALTER TABLE messages
  ADD CONSTRAINT chk_messages_body_not_empty CHECK (CHAR_LENGTH(TRIM(body)) > 0);

ALTER TABLE conversations
  ADD CONSTRAINT chk_conversations_distinct_users CHECK (tenant_id <> owner_id);

ALTER TABLE amenities
  ADD CONSTRAINT chk_amenities_name_not_empty CHECK (CHAR_LENGTH(TRIM(name)) > 0);

ALTER TABLE admin_logs
  ADD CONSTRAINT chk_admin_logs_action CHECK (CHAR_LENGTH(TRIM(action)) > 0),
  ADD CONSTRAINT chk_admin_logs_target_type CHECK (CHAR_LENGTH(TRIM(target_type)) > 0);
