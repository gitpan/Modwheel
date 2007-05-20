CREATE TABLE user_session (
    id  INTEGER PRIMARY KEY NOT NULL,
    userid INTEGER NOT NULL,
    username CHAR(255) NOT NULL,
    salt     CHAR(16) NOT NULL,
    addr     CHAR(64) NOT NULL,
    time_start INTEGER NOT NULL,
    time_expire INTEGER NOT NULL
);
    
