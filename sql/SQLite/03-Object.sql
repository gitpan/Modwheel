CREATE TABLE object (
    id            INTEGER PRIMARY_KEY NOT NULL,
    parent        INTEGER DEFAULT 1 NOT NULL,
    active        INTEGER(1) DEFAULT 1 NOT NULL,
    detach        INTEGER(1) DEFAULT 0 NOT NULL,
    type          CHAR(16) DEFAULT 'directory' NOT NULL,
    owner         INTEGER DEFAULT 1,
    groupo        INTEGER DEFAULT 1,
    revised_by    INTEGER DEFAULT 1,
    created       DATE,
    changed       DATE,
    sort          INTEGER(2) DEFAULT 0,
    karma         INTEGER DEFAULT 0,
    name          VARCHAR(255),
    keywords      VARCHAR(768),
    description   TEXT,
    data          TEXT,
    template      VARCHAR(255)
);


--    KEY data2 (name, keywords, description(768), data(999))
CREATE INDEX object_parent_idx ON object(parent);
CREATE INDEX object_changed_idx ON object(changed);
CREATE INDEX object_type_idx ON object(type);
CREATE INDEX object_active_idx ON object(active);                      
CREATE INDEX object_created_idx ON object(created);

INSERT INTO object (id, parent, active, owner, groupo, revised_by, type, name, description, created, changed) VALUES
( 1,    0, 1, 1, 1, 1, 'directory', 'root', 'Welcome to Modwheel.', DATETIME('NOW'), DATETIME('NOW'));
INSERT INTO object (id, parent, active, owner, groupo, revised_by, type, name, description, created, changed) VALUES
(-1,    0, 1, 1, 1, 1, 'directory', 'Trash', 'Dead, dismissed and objects waiting for deletion go here.', DATETIME('NOW'), DATETIME('NOW'));
INSERT INTO object (id, parent, active, owner, groupo, revised_by, type, name, description, created, changed) VALUES
(-10, -99, 1, 1, 1, 1, 'directory', 'NoParent', 'Objects with no parent directory sleeps here.', DATETIME('NOW'), DATETIME('NOW'));
INSERT INTO object (id, parent, active, owner, groupo, revised_by, type, name, description, created, changed) VALUES
(-11, -99, 1, 1, 1, 1, 'directory', 'DeadRefs', 'Dead references waiting for deletion or new location.', DATETIME('NOW'), DATETIME('NOW'));
