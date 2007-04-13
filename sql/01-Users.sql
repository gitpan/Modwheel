CREATE TABLE IF NOT EXISTS users
(
    id          int             AUTO_INCREMENT            NOT NULL,
    username    char(32)                                NOT NULL,
    password    char(64)                                NOT NULL,
    groups      varchar(255)    DEFAULT 100                NOT NULL,
    last_ip     char(16),
    real_name   varchar(128),
    email       varchar(128),
    comments    MEDIUMTEXT,
    PRIMARY KEY(id)
)
ENGINE = MYISAM;

CREATE TABLE IF NOT EXISTS groups
(
    id          int             AUTO_INCREMENT            NOT NULL,
    name        char(32)                                NOT NULL,
    password    char(64),
    PRIMARY KEY(id)
)
ENGINE = MYISAM;

#-- Create root user with default password: 'modwheel', and..
#-- ...guest user 
INSERT INTO users (id, username, password, groups, real_name) VALUES
(1, 'root', '0tiMyI2VJxJ1zqiMg9ksnWVIBNq4DPlw4Wx6IkJ15CltXtu', '1:100', 'superuser'),
(2, 'guest', '', '300', 'guest user');

INSERT INTO groups (id, name) VALUES
(  1, 'root'),
(100, 'users'),
(300, 'guests');
