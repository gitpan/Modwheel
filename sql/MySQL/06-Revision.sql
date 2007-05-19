
CREATE TABLE IF NOT EXISTS revision (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    version     float            NOT NULL default 1.0,
    approved    INT             NOT NULL default 0,
    objid       INT             NOT NULL,
    checksum    char(255)    NOT NULL,
    diff        TEXT,


    PRIMARY KEY(id)
) ENGINE = MyISAM ROW_FORMAT = DYNAMIC MAX_ROWS = 250000;

CREATE INDEX revision_objid_idx     ON revision(objid);
CREATE INDEX revision_version_idx   ON revision(version);

    
