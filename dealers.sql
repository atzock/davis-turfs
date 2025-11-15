-- SQL Schema for Drug Dealer Territory Control System
-- This table stores which faction owns which dealer

CREATE TABLE IF NOT EXISTS `dealer_ownership` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dealer_id` int(11) NOT NULL,
  `owner_job` varchar(50) DEFAULT NULL,
  `captured_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dealer_id` (`dealer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Optional: Table for tracking faction earnings if not using society accounts
CREATE TABLE IF NOT EXISTS `faction_earnings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
