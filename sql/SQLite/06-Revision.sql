
CREATE TABLE revision (
    id          INTEGER NOT NULL PRIMARY KEY,
    version     FLOAT NOT NULL default 1.0,
    approved    INTEGER(1) NOT NULL default 0,
    objid       INTEGER NOT NULL,
    checksum    VARCHAR(255) NOT NULL,
    diff        TEXT
);

CREATE INDEX revision_objid_idx     ON revision(objid);
CREATE INDEX revision_version_idx   ON revision(version);

    
