CREATE TABLE IF NOT EXISTS object
(
    id            INT                         AUTO_INCREMENT     NOT NULL,
    parent        INT             DEFAULT 1                      NOT NULL,
    active        BOOL            DEFAULT 1                      NOT NULL,
    detach        BOOL            DEFAULT 0                      NOT NULL,
    type        CHAR(16)          DEFAULT 'directory'            NOT NULL,
    owner        INT              DEFAULT 1,
    groupo        INT             DEFAULT 1,
    revised_by     INT            DEFAULT 1,
    created     TIMESTAMP         DEFAULT     CURRENT_TIMESTAMP,
    changed     TIMESTAMP,
    sort        TINYINT    SIGNED DEFAULT 0,
    karma       INT DEFAULT 0,
    name        VARCHAR(255),
    keywords     VARCHAR(768),
    description    MEDIUMTEXT,
    data         MEDIUMTEXT,
    template     VARCHAR(255),
    PRIMARY KEY(id),
    FULLTEXT KEY name (name),
    FULLTEXT KEY keywords (keywords),
    FULLTEXT KEY description (description),
    FULLTEXT KEY data (data),
    KEY keywords2(name(1), keywords(2), description(3)),
    FULLTEXT(name,keywords,description,data)
)
ENGINE = MYISAM ROW_FORMAT = DYNAMIC MAX_ROWS = 250000;


--    KEY data2 (name, keywords, description(768), data(999))
CREATE INDEX object_parent_idx ON object(parent);
CREATE INDEX object_changed_idx ON object(changed);
CREATE INDEX object_type_idx ON object(type);
CREATE INDEX object_active_idx ON object(active);                      
CREATE INDEX object_created_idx ON object(created);

INSERT INTO object (id, parent, active, owner, groupo, revised_by, type, name, description, created, changed)
VALUES
( 1,    0, 1, 1, 1, 1, 'directory', 'root', 'Welcome to Modwheel.', now(), now()),
(-1,    0, 1, 1, 1, 1, 'directory', 'Trash', 'Dead, dismissed and objects waiting for deletion go here.', now(), now()),
(-10, -99, 1, 1, 1, 1, 'directory', 'NoParent', 'Objects with no parent directory sleeps here.', now(), now()),
(-11, -99, 1, 1, 1, 1, 'directory', 'DeadRefs', 'Dead references waiting for deletion or new location.', now(), now());
