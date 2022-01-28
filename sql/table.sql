CREATE TABLE `forex` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pair` varchar(45) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `open` decimal(18,8) DEFAULT NULL,
  `high` decimal(18,8) DEFAULT NULL,
  `low` decimal(18,8) DEFAULT NULL,
  `close` decimal(18,8) DEFAULT NULL,
  `volume` int(11) DEFAULT NULL,
  `size` decimal(18,8) DEFAULT NULL,
  `rep_pattern` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `PAIR` (`pair`),
  KEY `REP_PATTERN` (`rep_pattern`)
) ENGINE=InnoDB AUTO_INCREMENT=2632951 DEFAULT CHARSET=utf8;
