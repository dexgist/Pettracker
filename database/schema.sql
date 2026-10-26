CREATE DATABASE IF NOT EXISTS pettrack CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pettrack;

CREATE TABLE users (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 role ENUM('admin','staff','owner') NOT NULL,
 active TINYINT(1) NOT NULL DEFAULT 1,
 must_change_password TINYINT(1) NOT NULL DEFAULT 0,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 INDEX idx_users_role_active(role,active)
) ENGINE=InnoDB;

CREATE TABLE pets (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 owner_id BIGINT UNSIGNED NOT NULL,
 name VARCHAR(100) NOT NULL,
 species ENUM('Dog','Cat','Bird','Other') NOT NULL,
 breed VARCHAR(100) NULL,
 sex ENUM('Female','Male') NULL,
 birth_date DATE NULL,
 color VARCHAR(100) NULL,
 weight_kg DECIMAL(7,2) NULL,
 health_notes TEXT NULL,
 photo_key VARCHAR(100) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_pets_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE RESTRICT,
 INDEX idx_pets_owner(owner_id)
) ENGINE=InnoDB;

CREATE TABLE pet_vaccinations (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 pet_id BIGINT UNSIGNED NOT NULL,
 vaccine_name VARCHAR(150) NOT NULL,
 administered_on DATE NULL,
 expires_on DATE NULL,
 notes VARCHAR(500) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_vaccination_pet FOREIGN KEY(pet_id) REFERENCES pets(id) ON DELETE CASCADE,
 INDEX idx_vaccination_pet(pet_id)
) ENGINE=InnoDB;

CREATE TABLE route_requirements (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(180) NOT NULL,
 description TEXT NULL,
 category VARCHAR(60) NOT NULL DEFAULT 'other',
 origin_province VARCHAR(120) NULL,
 destination_province VARCHAR(120) NULL,
 relocation_type VARCHAR(60) NULL,
 is_required TINYINT(1) NOT NULL DEFAULT 0,
 instructions TEXT NULL,
 validity_guidance VARCHAR(500) NULL,
 validity_days SMALLINT UNSIGNED NULL,
 authority_reference VARCHAR(500) NULL,
 active TINYINT(1) NOT NULL DEFAULT 1,
 updated_by BIGINT UNSIGNED NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_requirement_updater FOREIGN KEY(updated_by) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_requirements_route(active,origin_province,destination_province)
) ENGINE=InnoDB;

CREATE TABLE relocation_requests (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 reference_no VARCHAR(32) NOT NULL UNIQUE,
 pet_id BIGINT UNSIGNED NOT NULL,
 assigned_staff_id BIGINT UNSIGNED NULL,
 origin_city VARCHAR(120) NOT NULL,
 origin_province VARCHAR(120) NOT NULL,
 destination_city VARCHAR(120) NOT NULL,
 destination_province VARCHAR(120) NOT NULL,
 relocation_type VARCHAR(60) NOT NULL DEFAULT 'ground',
 pickup_address VARCHAR(250) NULL,
 dropoff_address VARCHAR(250) NULL,
 emergency_contact_name VARCHAR(120) NULL,
 emergency_contact_phone VARCHAR(40) NULL,
 requested_date DATE NOT NULL,
 preferred_time TIME NULL,
 notes TEXT NULL,
 status ENUM('request_submitted','request_confirmed','documents_pending','documents_under_review','corrections_required','documents_verified','pickup_scheduled','picked_up','in_transit','arrived','released','completed','cancelled') NOT NULL DEFAULT 'request_submitted',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_request_pet FOREIGN KEY(pet_id) REFERENCES pets(id) ON DELETE RESTRICT,
 CONSTRAINT fk_request_staff FOREIGN KEY(assigned_staff_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_request_status(status),
 INDEX idx_request_staff(assigned_staff_id),
 INDEX idx_request_date(requested_date)
) ENGINE=InnoDB;

CREATE TABLE request_requirement_snapshots (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NOT NULL,
 requirement_id BIGINT UNSIGNED NULL,
 name VARCHAR(180) NOT NULL,
 description TEXT NULL,
 category VARCHAR(60) NOT NULL,
 is_required TINYINT(1) NOT NULL DEFAULT 0,
 instructions TEXT NULL,
 validity_guidance VARCHAR(500) NULL,
 relocation_type VARCHAR(60) NULL,
 validity_days SMALLINT UNSIGNED NULL,
 authority_reference VARCHAR(500) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_snapshot_request FOREIGN KEY(request_id) REFERENCES relocation_requests(id) ON DELETE CASCADE,
 CONSTRAINT fk_snapshot_requirement FOREIGN KEY(requirement_id) REFERENCES route_requirements(id) ON DELETE SET NULL,
 INDEX idx_snapshot_request(request_id)
) ENGINE=InnoDB;

CREATE TABLE relocation_status_history (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NOT NULL,
 old_status VARCHAR(40) NULL,
 new_status VARCHAR(40) NOT NULL,
 actor_user_id BIGINT UNSIGNED NULL,
 notes VARCHAR(1000) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_history_request FOREIGN KEY(request_id) REFERENCES relocation_requests(id) ON DELETE RESTRICT,
 CONSTRAINT fk_history_actor FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_history_request(request_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE uploaded_documents (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NOT NULL,
 requirement_snapshot_id BIGINT UNSIGNED NOT NULL,
 owner_id BIGINT UNSIGNED NOT NULL,
 storage_key VARCHAR(100) NOT NULL UNIQUE,
 original_name VARCHAR(200) NOT NULL,
 mime_type VARCHAR(80) NOT NULL,
 size_bytes BIGINT UNSIGNED NOT NULL,
 valid_until DATE NULL,
 validity_reminder_sent_at DATETIME NULL,
 review_status ENUM('pending','verified','corrections') NOT NULL DEFAULT 'pending',
 feedback TEXT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_document_request FOREIGN KEY(request_id) REFERENCES relocation_requests(id) ON DELETE RESTRICT,
 CONSTRAINT fk_document_requirement FOREIGN KEY(requirement_snapshot_id) REFERENCES request_requirement_snapshots(id) ON DELETE RESTRICT,
 CONSTRAINT fk_document_owner FOREIGN KEY(owner_id) REFERENCES users(id) ON DELETE RESTRICT,
 INDEX idx_document_status(review_status)
) ENGINE=InnoDB;

CREATE TABLE document_reviews (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 document_id BIGINT UNSIGNED NOT NULL,
 reviewer_user_id BIGINT UNSIGNED NOT NULL,
 decision ENUM('verified','corrections') NOT NULL,
 feedback TEXT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_review_document FOREIGN KEY(document_id) REFERENCES uploaded_documents(id) ON DELETE RESTRICT,
 CONSTRAINT fk_review_user FOREIGN KEY(reviewer_user_id) REFERENCES users(id) ON DELETE RESTRICT,
 INDEX idx_review_document(document_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE pickup_dropoff_schedules (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 request_id BIGINT UNSIGNED NOT NULL,
 pickup_at DATETIME NOT NULL,
 pickup_location VARCHAR(250) NOT NULL,
 dropoff_location VARCHAR(250) NOT NULL,
 assigned_staff_id BIGINT UNSIGNED NULL,
 status ENUM('scheduled','changed','completed','cancelled') NOT NULL DEFAULT 'scheduled',
 instructions TEXT NULL,
 reminder_sent_at DATETIME NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_schedule_request FOREIGN KEY(request_id) REFERENCES relocation_requests(id) ON DELETE RESTRICT,
 CONSTRAINT fk_schedule_staff FOREIGN KEY(assigned_staff_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_schedule_time(pickup_at)
) ENGINE=InnoDB;

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

CREATE TABLE notifications (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 user_id BIGINT UNSIGNED NOT NULL,
 title VARCHAR(180) NOT NULL,
 message TEXT NOT NULL,
 record_type VARCHAR(50) NULL,
 record_id BIGINT UNSIGNED NULL,
 read_at DATETIME NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_notification_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 INDEX idx_notification_user(user_id,read_at,created_at)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 actor_user_id BIGINT UNSIGNED NULL,
 action VARCHAR(80) NOT NULL,
 record_type VARCHAR(50) NULL,
 record_id BIGINT UNSIGNED NULL,
 outcome ENUM('success','denied','failure') NOT NULL DEFAULT 'success',
 metadata_json JSON NULL,
 ip_address VARCHAR(45) NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_audit_actor FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_audit_time(created_at),
 INDEX idx_audit_action(action)
) ENGINE=InnoDB;
