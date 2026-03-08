CREATE TABLE IF NOT EXISTS `real_bank` (
  `identifier` varchar(50) NOT NULL,
  `info` longtext DEFAULT NULL,
  `credit` longtext DEFAULT NULL,
  `transaction` longtext DEFAULT NULL,
  `iban` int(4) DEFAULT NULL,
  `password` int(8) DEFAULT NULL,
  `AccountUsed` longtext DEFAULT NULL,
  PRIMARY KEY (`identifier`),
  UNIQUE KEY `real_bank_iban_unique` (`iban`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
