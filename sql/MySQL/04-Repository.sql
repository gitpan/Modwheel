CREATE TABLE IF NOT EXISTS repository
(
    id            INT    UNSIGNED    NOT NULL    AUTO_INCREMENT,
    parentobj    INT                NOT NULL,
    name        VARCHAR(255)    NOT NULL,
    mimetype    VARCHAR(128)    NOT NULL,
    path        VARCHAR(255)    NOT NULL,
    active        TINYINT            NOT NULL DEFAULT 1,
    created        TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,
    changed        TIMESTAMP,
    PRIMARY KEY(id),
    FULLTEXT KEY name(name)
)
ENGINE = MYISAM ROW_FORMAT = DYNAMIC AVG_ROW_LENGTH = 255 MAX_ROWS = 250000;

CREATE INDEX repository_parentobj_idx ON repository(parentobj);
CREATE INDEX repository_type_idx ON repository(mimetype);
CREATE INDEX repository_active_idx ON repository(active);
CREATE INDEX repository_name_idx ON repository(name);
