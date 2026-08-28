-- LearningStars / KTKP MySQL schema
-- Generated: 2026-08-28
-- Target: MySQL 8.0+, InnoDB, utf8mb4
--
-- Business rules represented by this schema:
-- 1. A formal case/result is created only when the contact form is submitted.
-- 2. One contact submission creates one star_contact row and may contain multiple child results.
-- 3. Assignment uses the existing KTKP mng_account.id through *_mid columns.
-- 4. One assignment creates one consolidated email containing every child's name and short URL.
-- 5. Short codes are opaque locators; the result page must still require KTKP login/authorization.
-- 6. Answers, calculated scores and result code are frozen in one star_result row at receipt time.
-- 7. Quiz questions and options have no version layer; editing them never recalculates old results.
--
-- Compatibility note:
-- Existing KTKP tables use legacy schemas whose exact id signedness is not declared in this
-- repository. assigned_mid/app_device_id are therefore indexed logical references without
-- FOREIGN KEY constraints. Add those constraints later only after DESCRIBE confirms matching types.

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `star_status` (
    `code` VARCHAR(32) NOT NULL COMMENT 'Stable workflow code',
    `name` VARCHAR(40) NOT NULL COMMENT 'Traditional Chinese display name',
    `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `is_terminal` TINYINT(1) NOT NULL DEFAULT 0,
    `state` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`code`),
    KEY `idx_learning_status_active_sort` (`state`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='LearningStars contact progress dictionary';

CREATE TABLE IF NOT EXISTS `star_quiz` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(50) NOT NULL,
    `title` VARCHAR(100) NOT NULL,
    `question_count` SMALLINT UNSIGNED NOT NULL,
    `main_score_question_count` SMALLINT UNSIGNED NOT NULL COMMENT 'Only Q1 through this number contribute T/E/G',
    `result_mapping_json` JSON NOT NULL COMMENT 'Mapping from leading T/E/G dimensions to result code',
    `state` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_quiz_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='LearningStars quiz identity';

CREATE TABLE IF NOT EXISTS `star_question` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `quiz_id` BIGINT UNSIGNED NOT NULL,
    `question_code` VARCHAR(10) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'Q1 through Q10',
    `question_no` SMALLINT UNSIGNED NOT NULL,
    `stage_name` VARCHAR(100) NOT NULL,
    `scene_text` TEXT NOT NULL,
    `question_text` TEXT NOT NULL,
    `observation_focus` VARCHAR(255) NOT NULL,
    `state` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_question_code` (`quiz_id`, `question_code`),
    UNIQUE KEY `uk_learning_question_no` (`quiz_id`, `question_no`),
    KEY `idx_learning_question_active` (`quiz_id`, `state`, `question_no`),
    CONSTRAINT `fk_lquestion_quiz`
        FOREIGN KEY (`quiz_id`) REFERENCES `star_quiz` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Questions imported from score.csv';

CREATE TABLE IF NOT EXISTS `star_option` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `question_id` BIGINT UNSIGNED NOT NULL,
    `answer_key` VARCHAR(10) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'For example Q1A',
    `option_code` CHAR(1) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'A through D',
    `option_text` VARCHAR(255) NOT NULL,
    `score_t` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_e` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_g` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_gd` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_et` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_gt` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_ps` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_ce` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `score_ou` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `answer_meaning` VARCHAR(255) NULL,
    `state` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_option_answer_key` (`answer_key`),
    UNIQUE KEY `uk_learning_option_code` (`question_id`, `option_code`),
    KEY `idx_learning_option_active` (`question_id`, `state`, `option_code`),
    CONSTRAINT `fk_loption_question`
        FOREIGN KEY (`question_id`) REFERENCES `star_question` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `chk_learning_option_code` CHECK (`option_code` IN ('A','B','C','D'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Question options and all T/E/G plus six-dimension scores imported from score2.csv';

CREATE TABLE IF NOT EXISTS `star_contact` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `schema_version` INT UNSIGNED NOT NULL DEFAULT 1,
    `status_code` VARCHAR(32) NOT NULL DEFAULT 'new',
    `assigned_mid` INT NULL COMMENT 'Logical reference to existing mng_account.id',
    `source` VARCHAR(50) NOT NULL DEFAULT 'learningstars-web',
    `parent_name` VARCHAR(40) NOT NULL,
    `phone` VARCHAR(30) NOT NULL,
    `email` VARCHAR(254) NULL,
    `contact_period` ENUM('am','pm') NOT NULL,
    `county_city` VARCHAR(40) NOT NULL,
    `children_json` JSON NOT NULL COMMENT 'All children in this submission, for example [{"seq":1,"name":"王小明","age":5}]',
    `contact_snapshot_json` JSON NOT NULL COMMENT 'Exact validated contact payload at submission time',
    `app_device_id` INT NULL COMMENT 'Optional logical reference to legacy app_device.id',
    `consent_education_contact` TINYINT(1) NOT NULL DEFAULT 1,
    `consent_copy_version` INT UNSIGNED NOT NULL,
    `consented_at` DATETIME(3) NOT NULL,
    `submitted_at` DATETIME(3) NOT NULL,
    `assigned_at` DATETIME(3) NULL,
    `last_contact_at` DATETIME(3) NULL,
    `next_follow_up_at` DATETIME(3) NULL,
    `closed_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_learning_contact_phone` (`phone`),
    KEY `idx_learning_contact_email` (`email`),
    KEY `idx_learning_contact_device` (`app_device_id`),
    KEY `idx_learning_contact_assignee_status` (`assigned_mid`, `status_code`),
    KEY `idx_learning_contact_status_followup` (`status_code`, `next_follow_up_at`),
    KEY `idx_learning_contact_submitted` (`submitted_at`),
    CONSTRAINT `fk_lcontact_status`
        FOREIGN KEY (`status_code`) REFERENCES `star_status` (`code`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One complete parent contact submission including all children and workflow state';

CREATE TABLE IF NOT EXISTS `star_result` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contact_id` BIGINT UNSIGNED NOT NULL,
    `child_seq` SMALLINT UNSIGNED NOT NULL COMMENT 'Matches seq in star_contact.children_json',
    `quiz_id` BIGINT UNSIGNED NOT NULL,
    `answer_count` SMALLINT UNSIGNED NOT NULL,
    `answers_json` JSON NOT NULL COMMENT 'Immutable answer snapshot, for example {"Q1":"A","Q2":"B"}',
    `score_t` SMALLINT UNSIGNED NOT NULL COMMENT '目標 T',
    `score_e` SMALLINT UNSIGNED NOT NULL COMMENT '探索 E',
    `score_g` SMALLINT UNSIGNED NOT NULL COMMENT '成長 G',
    `score_gd` SMALLINT UNSIGNED NOT NULL COMMENT '目標驅動 GD',
    `score_et` SMALLINT UNSIGNED NOT NULL COMMENT '探索思考 ET',
    `score_gt` SMALLINT UNSIGNED NOT NULL COMMENT '持續嘗試 GT',
    `score_ps` SMALLINT UNSIGNED NOT NULL COMMENT '問題解決 PS',
    `score_ce` SMALLINT UNSIGNED NOT NULL COMMENT '創意表達 CE',
    `score_ou` SMALLINT UNSIGNED NOT NULL COMMENT '觀察理解 OU',
    `result_code` VARCHAR(10) NOT NULL COMMENT 'Server-calculated result code such as R01 through R07',
    `submitted_at` DATETIME(3) NOT NULL,
    `calculated_at` DATETIME(3) NOT NULL COMMENT 'Time answers, scores and result were finalized by the receiver',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_result_contact_child` (`contact_id`, `child_seq`),
    KEY `idx_learning_result_quiz` (`quiz_id`, `result_code`, `submitted_at`),
    KEY `idx_learning_result_main_scores` (`score_t`, `score_e`, `score_g`),
    CONSTRAINT `fk_lresult_contact`
        FOREIGN KEY (`contact_id`) REFERENCES `star_contact` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_lresult_quiz`
        FOREIGN KEY (`quiz_id`) REFERENCES `star_quiz` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable receipt-time answers, calculated scores and result for one child';

CREATE TABLE IF NOT EXISTS `star_assignment` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contact_id` BIGINT UNSIGNED NOT NULL,
    `from_mid` INT NULL COMMENT 'Previous mng_account.id',
    `to_mid` INT NOT NULL COMMENT 'Assigned mng_account.id',
    `assigned_by_mid` INT NOT NULL COMMENT 'Operator mng_account.id',
    `reason` VARCHAR(255) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_learning_assignment_contact` (`contact_id`, `created_at`),
    KEY `idx_learning_assignment_to` (`to_mid`, `created_at`),
    KEY `idx_learning_assignment_by` (`assigned_by_mid`, `created_at`),
    CONSTRAINT `fk_lassignment_contact`
        FOREIGN KEY (`contact_id`) REFERENCES `star_contact` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only contact assignment history';

CREATE TABLE IF NOT EXISTS `star_link` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `result_id` BIGINT UNSIGNED NOT NULL,
    `assignment_id` BIGINT UNSIGNED NOT NULL,
    `public_code` CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '128-bit random value encoded as lowercase hex',
    `expires_at` DATETIME(3) NULL,
    `last_opened_at` DATETIME(3) NULL,
    `open_count` INT UNSIGNED NOT NULL DEFAULT 0,
    `revoked_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_link_code` (`public_code`),
    UNIQUE KEY `uk_learning_link_assignment_result` (`assignment_id`, `result_id`),
    KEY `idx_learning_link_result_active` (`result_id`, `revoked_at`, `expires_at`),
    CONSTRAINT `fk_llink_result`
        FOREIGN KEY (`result_id`) REFERENCES `star_result` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_llink_assignment`
        FOREIGN KEY (`assignment_id`) REFERENCES `star_assignment` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Per-child opaque result links scoped to an assignment';

CREATE TABLE IF NOT EXISTS `star_mail` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contact_id` BIGINT UNSIGNED NOT NULL,
    `assignment_id` BIGINT UNSIGNED NOT NULL,
    `recipient_mid` INT NOT NULL COMMENT 'Recipient mng_account.id',
    `recipient_name_snapshot` VARCHAR(40) NOT NULL,
    `recipient_email_snapshot` VARCHAR(254) NOT NULL,
    `subject` VARCHAR(255) NOT NULL,
    `payload_json` JSON NOT NULL COMMENT 'One email snapshot containing all child names and result URLs',
    `status` ENUM('pending','sending','sent','failed','cancelled') NOT NULL DEFAULT 'pending',
    `attempt_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `next_attempt_at` DATETIME(3) NULL,
    `last_attempt_at` DATETIME(3) NULL,
    `sent_at` DATETIME(3) NULL,
    `provider_message_id` VARCHAR(255) NULL,
    `last_error` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_mail_assignment` (`assignment_id`),
    KEY `idx_learning_mail_dispatch` (`status`, `next_attempt_at`, `created_at`),
    KEY `idx_learning_mail_contact` (`contact_id`, `created_at`),
    KEY `idx_learning_mail_recipient` (`recipient_mid`, `created_at`),
    CONSTRAINT `fk_lmail_contact`
        FOREIGN KEY (`contact_id`) REFERENCES `star_contact` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_lmail_assignment`
        FOREIGN KEY (`assignment_id`) REFERENCES `star_assignment` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Transactional outbox and audit record for consolidated assignment emails';

CREATE TABLE IF NOT EXISTS `star_activity` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contact_id` BIGINT UNSIGNED NOT NULL,
    `actor_mid` INT NULL COMMENT 'Operator mng_account.id; NULL for system activity',
    `activity_type` ENUM('status','note','call','email','assignment','system') NOT NULL,
    `from_status_code` VARCHAR(32) NULL,
    `to_status_code` VARCHAR(32) NULL,
    `note` TEXT NULL,
    `next_follow_up_at` DATETIME(3) NULL,
    `metadata_json` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    KEY `idx_learning_activity_contact` (`contact_id`, `created_at`),
    KEY `idx_learning_activity_actor` (`actor_mid`, `created_at`),
    KEY `idx_learning_activity_followup` (`next_follow_up_at`),
    CONSTRAINT `fk_lactivity_contact`
        FOREIGN KEY (`contact_id`) REFERENCES `star_contact` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_lactivity_from_status`
        FOREIGN KEY (`from_status_code`) REFERENCES `star_status` (`code`)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_lactivity_to_status`
        FOREIGN KEY (`to_status_code`) REFERENCES `star_status` (`code`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Append-only contact, note and workflow history';

START TRANSACTION;

INSERT INTO `star_status`
    (`code`, `name`, `sort_order`, `is_terminal`, `state`)
VALUES
    ('new',             '新案件',       10, 0, 1),
    ('assigned',        '已指派',       20, 0, 1),
    ('contact_pending', '待聯絡',       30, 0, 1),
    ('contacted',       '已聯絡',       40, 0, 1),
    ('follow_up',       '持續追蹤',     50, 0, 1),
    ('appointment',     '已預約',       60, 0, 1),
    ('converted',       '已轉換',       70, 1, 1),
    ('unreachable',     '無法聯絡',     80, 1, 1),
    ('not_interested',  '無意願',       90, 1, 1),
    ('closed',          '已結案',      100, 1, 1)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `sort_order` = VALUES(`sort_order`),
    `is_terminal` = VALUES(`is_terminal`),
    `state` = VALUES(`state`);

INSERT INTO `star_quiz`
    (`code`, `title`, `question_count`, `main_score_question_count`, `result_mapping_json`, `state`)
VALUES
    (
        'learning-stars',
        '學習星球探索測驗',
        10,
        6,
        JSON_OBJECT(
            'target','R01',
            'explore','R02',
            'growth','R03',
            'target+explore','R04',
            'target+growth','R05',
            'explore+growth','R06',
            'target+explore+growth','R07'
        ),
        1
    )
ON DUPLICATE KEY UPDATE
    `id` = LAST_INSERT_ID(`id`),
    `title` = VALUES(`title`),
    `question_count` = VALUES(`question_count`),
    `main_score_question_count` = VALUES(`main_score_question_count`),
    `result_mapping_json` = VALUES(`result_mapping_json`),
    `state` = VALUES(`state`);

SET @star_quiz_id := LAST_INSERT_ID();

INSERT INTO `star_question`
    (`quiz_id`, `question_code`, `question_no`, `stage_name`, `scene_text`, `question_text`, `observation_focus`, `state`)
VALUES
    (@star_quiz_id, 'Q1', 1, '登上學習飛船', '第一次登上學習飛船，眼前出現陌生的控制台和四個按鈕。', '孩子最可能先做什麼？', '面對陌生任務時的啟動方式', 1),
    (@star_quiz_id, 'Q2', 2, '神祕星球', '飛船降落在神祕星球，孩子遇到一個沒有說明、打不開的神祕盒子。', '為了打開盒子，孩子最可能怎麼做？', '面對未知事物時的理解與處理方式', 1),
    (@star_quiz_id, 'Q3', 3, '穿越隕石風暴', '飛船前方出現隕石風暴，需要繼續前進。', '飛船遇上隕石風暴時，孩子最可能怎麼做？', '遇到阻礙時的處理起點', 1),
    (@star_quiz_id, 'Q4', 4, '四顆神祕星球', '孩子可以選擇一顆星球開始新的旅程。', '孩子最想前往哪一顆星球？', '偏好的任務體驗', 1),
    (@star_quiz_id, 'Q5', 5, '星際圖書館', '飛船來到星際圖書館，書架上放著四本不同的書。', '孩子最可能先拿哪一本？', '偏好的學習內容與參與形式', 1),
    (@star_quiz_id, 'Q6', 6, '選擇星際角色', '旅程來到最後一站，孩子可以選一個角色參與星際任務。', '依照你對孩子的了解，他最可能選哪個角色？', '任務角色與參與方式偏好', 1),
    (@star_quiz_id, 'Q7', 7, '收到神祕任務', '飛船收到一個沒有說明的新任務，孩子準備開始挑戰。', '面對沒有說明的新任務，哪一種方式最能幫助孩子開始？', '開始新任務時需要的支持方式', 1),
    (@star_quiz_id, 'Q8', 8, '｜看懂星際圖', '孩子照著星際圖的步驟試過，還是不太明白。', '這時，孩子最可能怎麼幫助自己弄懂？', '遇到不理解時的處理方式', 1),
    (@star_quiz_id, 'Q9', 9, '修復能量拼圖', '孩子修復能量拼圖，試了兩次仍顯示錯誤。', '發現錯誤後，孩子最可能怎麼做？', '發現錯誤後的調整方式', 1),
    (@star_quiz_id, 'Q10', 10, '選擇下一段旅程', '完成一段旅程後，孩子準備繼續探索下一個星球。', '孩子持續投入時，最在意什麼？', '持續投入的主要動機', 1)
ON DUPLICATE KEY UPDATE
    `question_no` = VALUES(`question_no`),
    `stage_name` = VALUES(`stage_name`),
    `scene_text` = VALUES(`scene_text`),
    `question_text` = VALUES(`question_text`),
    `observation_focus` = VALUES(`observation_focus`),
    `state` = VALUES(`state`);

INSERT INTO `star_option`
    (`question_id`, `answer_key`, `option_code`, `option_text`,
     `score_t`, `score_e`, `score_g`, `score_gd`, `score_et`, `score_gt`, `score_ps`, `score_ce`, `score_ou`,
     `answer_meaning`, `state`)
VALUES
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q1'), 'Q1A', 'A', '看任務說明', 2,0,0, 2,0,0,0,0,1, '先確認任務內容與完成方向', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q1'), 'Q1B', 'B', '研究機關', 0,2,0, 0,2,0,0,0,1, '先研究它是怎麼回事', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q1'), 'Q1C', 'C', '直接動手', 0,0,2, 0,0,2,1,0,0, '直接動手試試看', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q1'), 'Q1D', 'D', '想新玩法試試', 0,1,1, 0,0,1,0,2,0, '自己想出新玩法並動手嘗試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q2'), 'Q2A', 'A', '尋找提示', 2,0,0, 1,0,0,2,0,0, '以解決目標為主', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q2'), 'Q2B', 'B', '研究機關', 0,2,0, 0,2,0,0,0,1, '研究構造與原理', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q2'), 'Q2C', 'C', '想新方法試試', 0,0,2, 0,0,1,0,2,0, '創造不同方法並嘗試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q2'), 'Q2D', 'D', '先觀察，猜了再試', 0,1,1, 0,2,0,0,0,1, '觀察線索並形成猜想', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q3'), 'Q3A', 'A', '換條航線', 0,0,2, 0,0,0,2,1,0, '換方法', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q3'), 'Q3B', 'B', '找出隕石規律', 0,2,0, 0,0,0,2,0,1, '找規律', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q3'), 'Q3C', 'C', '確認方向再前進', 2,0,0, 2,0,0,1,0,0, '看目標', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q3'), 'Q3D', 'D', '停一下再試', 1,0,1, 1,0,2,0,0,0, '稍後重試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q4'), 'Q4A', 'A', '挑戰星球 完成任務', 2,0,0, 2,0,0,1,0,0, '喜歡挑戰與完成', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q4'), 'Q4B', 'B', '發現星球 找出祕密', 0,2,0, 0,2,0,0,0,1, '喜歡發現與理解', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q4'), 'Q4C', 'C', '探險星球 體驗冒險', 0,0,2, 0,0,2,0,1,0, '喜歡親身體驗與嘗試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q4'), 'Q4D', 'D', '創造星球 動手完成作品', 1,0,1, 1,0,0,0,2,0, '喜歡自已動手創作', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q5'), 'Q5A', 'A', '闖關任務書 完成任務', 2,0,0, 2,0,0,1,0,0, '完成目標', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q5'), 'Q5B', 'B', '趣味發現書 認識新事物', 0,2,0, 0,2,0,0,0,1, '新奇事物，觀察、認識與了解', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q5'), 'Q5C', 'C', '實驗探險書 動手答案', 0,0,2, 0,2,0,0,1,0, '操作嘗試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q5'), 'Q5D', 'D', '創意故事書 想故事並完成', 1,1,0, 0,1,0,0,2,0, '發想並完成', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q6'), 'Q6A', 'A', '任務導航員 朝著目標完成', 2,0,0, 2,0,0,1,0,0, '是否喜歡有明確方向，並朝著目標完成', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q6'), 'Q6B', 'B', '星際解謎家 找出謎題答案', 0,2,0, 0,1,0,2,0,0, '是否喜歡思考問題、尋找線索與答案', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q6'), 'Q6C', 'C', '勇氣探險家 看清狀況再試', 0,0,2, 0,0,2,0,0,1, '是否願意在失敗後繼續嘗試', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q6'), 'Q6D', 'D', '創意發明家 用新方法完成', 1,1,0, 0,0,0,1,2,0, '是否喜歡想出不同方法，並完成目標', 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q7'), 'Q7A', 'A', '先看完成的樣子', 0,0,0, 2,0,0,0,0,1, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q7'), 'Q7B', 'B', '先找線索', 0,0,0, 0,1,0,0,0,2, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q7'), 'Q7C', 'C', '直接動手試試', 0,0,0, 0,0,2,1,0,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q7'), 'Q7D', 'D', '想自己的方法', 0,0,0, 0,0,0,1,2,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q8'), 'Q8A', 'A', '再問問原因', 0,0,0, 0,2,0,1,0,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q8'), 'Q8B', 'B', '再看一次示範', 0,0,0, 0,1,0,0,0,2, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q8'), 'Q8C', 'C', '邊操作邊觀察', 0,0,0, 0,0,2,0,0,1, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q8'), 'Q8D', 'D', '回頭查看步驟', 0,0,0, 0,0,0,1,0,2, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q9'), 'Q9A', 'A', '找出錯在哪裡', 0,0,0, 0,0,0,2,0,1, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q9'), 'Q9B', 'B', '換個方法再試', 0,0,0, 0,0,1,0,2,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q9'), 'Q9C', 'C', '繼續試到完成', 0,0,0, 2,0,1,0,0,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q9'), 'Q9D', 'D', '看完別人再試', 0,0,0, 0,0,1,0,0,2, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q10'), 'Q10A', 'A', '離完成還有多遠', 0,0,0, 2,0,1,0,0,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q10'), 'Q10B', 'B', '過程有新發現', 0,0,0, 0,2,0,0,0,1, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q10'), 'Q10C', 'C', '可以嘗試不同方法', 0,0,0, 0,0,2,0,1,0, NULL, 1),
    ((SELECT `id` FROM `star_question` WHERE `quiz_id`=@star_quiz_id AND `question_code`='Q10'), 'Q10D', 'D', '能加入自己的想法', 0,0,0, 1,0,0,0,2,0, NULL, 1)
ON DUPLICATE KEY UPDATE
    `question_id` = VALUES(`question_id`),
    `option_code` = VALUES(`option_code`),
    `option_text` = VALUES(`option_text`),
    `score_t` = VALUES(`score_t`),
    `score_e` = VALUES(`score_e`),
    `score_g` = VALUES(`score_g`),
    `score_gd` = VALUES(`score_gd`),
    `score_et` = VALUES(`score_et`),
    `score_gt` = VALUES(`score_gt`),
    `score_ps` = VALUES(`score_ps`),
    `score_ce` = VALUES(`score_ce`),
    `score_ou` = VALUES(`score_ou`),
    `answer_meaning` = VALUES(`answer_meaning`),
    `state` = VALUES(`state`);

COMMIT;

-- Application transaction boundary for POST /contact:
-- one star_contact with children_json -> calculate answers/scores/result -> one star_result per child -> COMMIT
-- Do not create these formal records from POST /assessment-statistics alone.
-- star_result is append-only assessment history. Editing star_question/star_option never
-- updates answers, scores or result_code in an existing result row.
--
-- Assignment transaction boundary:
-- update contact.assigned_mid/status -> assignment -> one link per result -> one mail row -> COMMIT
-- Only after COMMIT should the application call SendGrid and update star_mail.
