-- Apply once to existing PetTrack installations after taking a database backup.
ALTER TABLE relocation_requests
 ADD COLUMN relocation_type VARCHAR(60) NOT NULL DEFAULT 'ground' AFTER destination_province,
 ADD COLUMN emergency_contact_name VARCHAR(120) NULL AFTER dropoff_address,
 ADD COLUMN emergency_contact_phone VARCHAR(40) NULL AFTER emergency_contact_name;

ALTER TABLE route_requirements
 ADD COLUMN validity_days SMALLINT UNSIGNED NULL AFTER validity_guidance,
 ADD COLUMN authority_reference VARCHAR(500) NULL AFTER validity_days;

ALTER TABLE request_requirement_snapshots
 ADD COLUMN relocation_type VARCHAR(60) NULL AFTER validity_guidance,
 ADD COLUMN validity_days SMALLINT UNSIGNED NULL AFTER relocation_type,
 ADD COLUMN authority_reference VARCHAR(500) NULL AFTER validity_days;

ALTER TABLE uploaded_documents
 ADD COLUMN valid_until DATE NULL AFTER size_bytes,
 ADD COLUMN validity_reminder_sent_at DATETIME NULL AFTER valid_until;

CREATE TABLE schedule_change_history (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 schedule_id BIGINT UNSIGNED NOT NULL,
 actor_user_id BIGINT UNSIGNED NULL,
 action ENUM('created','updated') NOT NULL,
 old_data JSON NULL,
 new_data JSON NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_schedule_history_schedule FOREIGN KEY(schedule_id) REFERENCES pickup_dropoff_schedules(id) ON DELETE RESTRICT,
 CONSTRAINT fk_schedule_history_actor FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_schedule_history(schedule_id,created_at)
) ENGINE=InnoDB;
