-- LearningStars / KTKP MySQL schema
-- Updated: 2026-08-31
-- Target: MySQL 8.0+, InnoDB, utf8mb4
--
-- Business rules represented by this schema:
-- 1. POST /result stores one completed quiz and returns an opaque result_token.
-- 2. POST /contact resolves result_token, then stores one contact row linked to that result.
-- 3. UNIQUE star_contact.result_id makes repeated contact requests for the same result idempotent.
--    The same parent/phone/email with another result_token intentionally creates another contact row.
-- 4. A contact row is the signal to create one mail outbox row for the configured fixed mailbox.
-- 5. Answers, calculated scores and result code are frozen in star_result at receipt time.
-- 6. Quiz questions and options have no version layer; editing them never recalculates old results.
--
-- Compatibility note:
-- Existing KTKP tables use legacy schemas whose exact id signedness is not declared in this
-- repository. app_device_id is therefore an indexed logical reference without a FOREIGN KEY.
-- Add that constraint later only after DESCRIBE confirms matching types.

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

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
    `level_no` TINYINT UNSIGNED NOT NULL COMMENT 'LEVEL 1 or LEVEL 2 in score2.csv',
    `stage_name` VARCHAR(100) NOT NULL,
    `question_text` TEXT NOT NULL,
    `observation_topic` VARCHAR(100) NULL,
    `parent_observation` TEXT NULL,
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
  COMMENT='Questions imported from score2.csv';

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

CREATE TABLE IF NOT EXISTS `star_result` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `result_token` CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT '128-bit random lowercase hex token returned by POST /result',
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
    UNIQUE KEY `uk_learning_result_token` (`result_token`),
    KEY `idx_learning_result_quiz` (`quiz_id`, `result_code`, `submitted_at`),
    KEY `idx_learning_result_main_scores` (`score_t`, `score_e`, `score_g`),
    CONSTRAINT `fk_lresult_quiz`
        FOREIGN KEY (`quiz_id`) REFERENCES `star_quiz` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Anonymous immutable receipt-time answers, scores and result';

CREATE TABLE IF NOT EXISTS `star_contact` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `result_id` BIGINT UNSIGNED NOT NULL,
    `schema_version` INT UNSIGNED NOT NULL DEFAULT 1,
    `source` VARCHAR(50) NOT NULL DEFAULT 'learningstars-web',
    `parent_name` VARCHAR(40) NOT NULL,
    `phone` VARCHAR(30) NOT NULL,
    `email` VARCHAR(254) NULL,
    `contact_period` ENUM('am','pm') NOT NULL,
    `county_city` VARCHAR(40) NOT NULL,
    `child_name` VARCHAR(40) NOT NULL,
    `child_age` TINYINT UNSIGNED NULL,
    `contact_snapshot_json` JSON NOT NULL COMMENT 'Exact validated contact payload at submission time',
    `app_device_id` INT NULL COMMENT 'Optional logical reference to legacy app_device.id',
    `consent_education_contact` TINYINT(1) NOT NULL DEFAULT 1,
    `consent_copy_version` INT UNSIGNED NOT NULL,
    `consented_at` DATETIME(3) NOT NULL,
    `submitted_at` DATETIME(3) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_contact_result` (`result_id`),
    KEY `idx_learning_contact_phone` (`phone`),
    KEY `idx_learning_contact_email` (`email`),
    KEY `idx_learning_contact_device` (`app_device_id`),
    KEY `idx_learning_contact_submitted` (`submitted_at`),
    CONSTRAINT `fk_lcontact_result`
        FOREIGN KEY (`result_id`) REFERENCES `star_result` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='One parent and child contact submission linked to one quiz result';

CREATE TABLE IF NOT EXISTS `star_mail` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `contact_id` BIGINT UNSIGNED NOT NULL,
    `recipient_name` VARCHAR(100) NULL COMMENT 'Configured fixed mailbox display name snapshot',
    `recipient_email` VARCHAR(254) NOT NULL COMMENT 'Configured fixed mailbox address snapshot',
    `subject` VARCHAR(255) NOT NULL,
    `payload_json` JSON NOT NULL COMMENT 'Exact email payload snapshot, including child name and result URL',
    `status` ENUM('pending','sent','failed') NOT NULL DEFAULT 'pending',
    `attempt_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `last_attempt_at` DATETIME(3) NULL,
    `sent_at` DATETIME(3) NULL,
    `provider_message_id` VARCHAR(255) NULL,
    `last_error` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_learning_mail_contact` (`contact_id`),
    KEY `idx_learning_mail_dispatch` (`status`, `created_at`),
    KEY `idx_learning_mail_recipient` (`recipient_email`, `created_at`),
    CONSTRAINT `fk_lmail_contact`
        FOREIGN KEY (`contact_id`) REFERENCES `star_contact` (`id`)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Transactional outbox and delivery audit for the fixed notification mailbox';

START TRANSACTION;

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
    (`quiz_id`, `question_code`, `question_no`, `level_no`, `stage_name`, `question_text`, `observation_topic`, `parent_observation`, `state`)
VALUES
    (@star_quiz_id, 'Q1', 1, 1, '登上學習飛船', '第一次登上學習飛船，眼前出現陌生的控制台和四個按鈕。孩子最可能先做什麼？', '學習啟動方式', '了解孩子第一次接觸陌生事物時，通常會先確認說明、研究原理、直接嘗試，還是自行發想玩法。', 1),
    (@star_quiz_id, 'Q2', 2, 1, '神秘盒子', '飛船降落神祕星球，一個沒有說明、打不開的盒子出現在眼前。想打開盒子時，孩子最可能怎麼做？', '理解與解題方式', '了解孩子面對不理解或暫時無法處理的事物時，通常會尋找提示、研究原因、動手測試，還是先猜想再嘗試。', 1),
    (@star_quiz_id, 'Q3', 3, 1, '遇到隕石風暴', '飛船飛向下一個星球時，飛船遇上隕石風暴時，孩子最可能先做什麼？', '遇到阻礙時的調整方式', '了解孩子遇到困難或原方法行不通時，通常會立即換方法、找出問題、朝目標繼續，還是先停一下再重新投入。', 1),
    (@star_quiz_id, 'Q4', 4, 1, '四顆神秘星球', '穿越隕石風暴後，眼前出現四顆神祕星球。 孩子最想前往哪一顆？', '活動經驗偏好', '了解孩子較容易被完成挑戰、發現祕密、親身冒險，或動手創作等哪一種活動經驗吸引。', 1),
    (@star_quiz_id, 'Q5', 5, 1, '星際圖書館', '飛船來到星際圖書館，書架上放著四本不同的書。 孩子最可能先拿哪一本？', '學習內容偏好', '了解孩子較容易被任務闖關、新奇知識、動手體驗，或故事創作等哪一類書籍內容與參與形式吸引。', 1),
    (@star_quiz_id, 'Q6', 6, 1, '選擇星際角色', '旅程來到最後一站，孩子可以選一個角色參與星際任務。 依照平常表現孩子最適合哪個角色？', '任務角色偏好', '了解孩子參與任務時，較認同朝目標完成、找出答案、失敗後再試，或運用新方法完成等哪一種角色與做事方式。', 1),
    (@star_quiz_id, 'Q7', 7, 2, '收到神秘任務', '飛船收到一個沒有說明的新任務，孩子準備開始挑戰 ，孩子最可能先做什麼？', NULL, '學習啟動方式', 1),
    (@star_quiz_id, 'Q8', 8, 2, '看懂星際圖', '當照著星際圖的步驟試過，還是不太明白時，孩子最可能怎麼做？', NULL, NULL, 1),
    (@star_quiz_id, 'Q9', 9, 2, '修復能量拼圖', '在修復能量拼圖時，試了兩次仍顯示錯誤。孩子最可能怎麼做？', NULL, NULL, 1),
    (@star_quiz_id, 'Q10', 10, 2, '選擇下一段旅程', '完成一段旅程後，孩子準備繼續探索下一個星球。什麼最能讓你的孩子繼續投入？', NULL, NULL, 1)
ON DUPLICATE KEY UPDATE
    `question_no` = VALUES(`question_no`),
    `level_no` = VALUES(`level_no`),
    `stage_name` = VALUES(`stage_name`),
    `question_text` = VALUES(`question_text`),
    `observation_topic` = VALUES(`observation_topic`),
    `parent_observation` = VALUES(`parent_observation`),
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

-- POST /result:
-- Validate selected answer keys against active star_option rows, calculate every score/result,
-- generate bin2hex(random_bytes(16)), insert one star_result, COMMIT, then return result_token.
-- star_result is append-only assessment history. Editing star_question/star_option never updates
-- answers, scores or result_code in an existing result row.
--
-- POST /contact:
-- Resolve result_token to result_id. In one transaction, insert star_contact and one pending
-- star_mail row using the configured fixed recipient. UNIQUE star_contact.result_id is the only
-- contact deduplication rule; matching parent name, phone or email must not merge different results.
-- After COMMIT, send the email and update star_mail to sent or failed.
