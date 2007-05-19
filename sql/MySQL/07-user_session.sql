CREATE TABLE user_session (
    id  INT UNSIGNED AUTO_INCREMENT NOT NULL,
    userid INT UNSIGNED NOT NULL,
    username CHAR(255) NOT NULL,
    salt     CHAR(16) NOT NULL,
    addr     CHAR(64) NOT NULL,
    time_start INT UNSIGNED NOT NULL,
    time_expire INT UNSIGNED NOT NULL,
    PRIMARY KEY (id)
) ENGINE = MyISAM ROW_FORMAT = FIXED AVG_ROW_LENGTH = 200 MAX_ROWS = 250000;
    