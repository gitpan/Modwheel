
CREATE TABLE IF NOT EXISTS revision (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    version     float            NOT NULL default 1.0,
    approved    INT             NOT NULL default 0,
    objid       INT             NOT NULL,
    checksum    VARCHAR(255)    NOT NULL,
    diff        TEXT,


    PRIMARY KEY(id)
);

CREATE INDEX revision_objid_idx     ON revision(objid);
CREATE INDEX revision_version_idx   ON revision(version);

    
