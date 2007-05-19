CREATE TABLE users (
    id INTEGER PRIMARY KEY NOT NULL,
    username CHAR(32) NOT NULL,
    password CHAR(64) NOT NULL,
    groups VARCHAR(255) DEFAULT 100 NOT NULL,
    last_ip CHAR(16),
    real_name VARCHAR(128),
    email VARCHAR(128),
    comments TEXT
);

CREATE TABLE groups (
    id INTEGER PRIMARY_KEY NOT NULL,
    name CHAR(32) NOT NULL,
    password CHAR(64)
);

-- Create root uer with default password: 'modwheel', and..
-- ...guest user 
INSERT INTO users (id, username, password, groups, real_name) VALUES
(1, 'root', '0tiMyI2VJxJ1zqiMg9ksnWVIBNq4DPlw4Wx6IkJ15CltXtu', '1:100', 'superuser');
INSERT INTO users (id, username, password, groups, real_name) VALUES
(2, 'guest', '', '300', 'guest user');

INSERT INTO groups (id, name) VALUES
(  1, 'root');
INSERT INTO groups (id, name) VALUES
(100, 'users');
INSERT INTO groups (id, name) VALUES
(300, 'guests');
