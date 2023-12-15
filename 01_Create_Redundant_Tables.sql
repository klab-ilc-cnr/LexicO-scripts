/*
 * @author Simone Marchi <simone.marchi(at)ilc.cnr.it>
 */
CREATE TABLE `RedundantPhu` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idRedundant` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `idRedundantOf` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `status` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `RedundantPHU_UN` (`idRedundant`,`idRedundantOf`),
  KEY `RedundantPHU_FK_1` (`idRedundantOf`),
  CONSTRAINT `RedundantPHU_FK` FOREIGN KEY (`idRedundant`) REFERENCES `phu` (`idPhu`) ON DELETE CASCADE,
  CONSTRAINT `RedundantPHU_FK_1` FOREIGN KEY (`idRedundantOf`) REFERENCES `phu` (`idPhu`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `RedundantUsem` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idRedundant` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `idRedundantOf` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `status` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `RedundantUsem_UN` (`idRedundant`,`idRedundantOf`,`status`),
  KEY `RedundantUsem_FK_1` (`idRedundantOf`),
  CONSTRAINT `RedundantUsem_FK` FOREIGN KEY (`idRedundant`) REFERENCES `usem` (`idUsem`)  ON DELETE CASCADE,
  CONSTRAINT `RedundantUsem_FK_1` FOREIGN KEY (`idRedundantOf`) REFERENCES `usem` (`idUsem`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `RedundantUsyn` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idRedundant` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `idRedundantOf` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `status` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `RedundantUsyn_UN` (`idRedundant`,`idRedundantOf`,`status`),
  KEY `RedundantUsyn_UN_1` (`idRedundantOf`),
  CONSTRAINT `RedundantUsyn_FK` FOREIGN KEY (`idRedundant`) REFERENCES `usyns` (`idUsyn`)  ON DELETE CASCADE,
  CONSTRAINT `RedundantUsyn_FK_1` FOREIGN KEY (`idRedundantOf`) REFERENCES `usyns` (`idUsyn`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE `RedundantMus` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idRedundant` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `idRedundantOf` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `status` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `RedundantMus_UN` (`idRedundant`,`idRedundantOf`,`status`),
  KEY `RedundantMus_FK_1` (`idRedundantOf`),
  CONSTRAINT `RedundantMus_FK` FOREIGN KEY (`idRedundant`) REFERENCES `mus` (`idMus`) ON DELETE CASCADE,
  CONSTRAINT `RedundantMus_FK_1` FOREIGN KEY (`idRedundantOf`) REFERENCES `mus` (`idMus`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
