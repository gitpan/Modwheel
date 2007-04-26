
CREATE TABLE IF NOT EXISTS prototype (
    id          INT       NOT NULL AUTO_INCREMENT,
    type        char(16)  NOT NULL,

    name        char(255) DEFAULT 'name',
    keywords    char(255) DEFAULT 'keywords',
    description char(255) DEFAULT 'description',
    data        char(255) DEFAULT 'data',

    PRIMARY KEY(id)
);

CREATE INDEX prototype_type_idx ON prototype(type);

INSERT INTO prototype (id, type, name, keywords, description, data)
VALUES
    (1, 'directory', 'Name',  'Keywords', 'Description', NULL),
    (2, 'article',   'Title', 'Keywords', 'Summary', 'Article text'),
    (3, 'link',      'Name',  'Keywords', 'Description', 'URL')
;
