CREATE TABLE repository (
    id          INTEGER NOT NULL PRIMARY KEY,
    parentobj   INTEGER NOT NULL,
    name        VARCHAR(255) NOT NULL,
    mimetype    VARCHAR(128) NOT NULL,
    path        VARCHAR(255) NOT NULL,
    active      INTEGER(1) NOT NULL DEFAULT 1,
    created     DATE, 
    changed     DATE
);

CREATE INDEX repository_parentobj_idx ON repository(parentobj);
CREATE INDEX repository_type_idx ON repository(mimetype);
CREATE INDEX repository_active_idx ON repository(active);
CREATE INDEX repository_name_idx ON repository(name);
