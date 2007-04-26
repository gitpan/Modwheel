CREATE TABLE IF NOT EXISTS objtagmap
(
    id        INT            AUTO_INCREMENT    NOT NULL,
    objid    INT                         NOT NULL,
    tagid     INT                         NOT NULL,
    PRIMARY KEY(id)
)
ENGINE = MyISAM;

CREATE TABLE IF NOT EXISTS tags
(
    tagid    INT            AUTO_INCREMENT    NOT NULL,
    name    char(32)                    NOT NULL,
    PRIMARY KEY(tagid)    
)
ENGINE = MyISAM;

-- Select all tags for a object: argument: object_id
-- SELECT t.name FROM objtagmap m, tags t WHERE m.objid=? AND m.tagid = t.tagid;

-- Create a new tag: argument: string tag_name.
-- INSERT INTO tags(name) VALUES('?')

-- Associate a tag with a object: arguments: object_id, tag_id
-- INSERT INTO objtagmap(objid, tagid) VALUES(?, ?)

-- Fetch all objects with tag (tagid)
-- SELECT o.name FROM object o, objtagmap m, tags t
--  WHERE o.id = m.objid
--   AND (t.name IN ('Programming'))
--  GROUP BY o.id
