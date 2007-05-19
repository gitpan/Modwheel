
CREATE TABLE prototype (
    id          INTEGER NOT NULL PRIMARY KEY,
    type        CHAR(16)  NOT NULL,

    name        CHAR(255) DEFAULT 'name',
    keywords    CHAR(255) DEFAULT 'keywords',
    description CHAR(255) DEFAULT 'description',
    data        CHAR(255) DEFAULT 'data'
);

CREATE INDEX prototype_type_idx ON prototype(type);

INSERT INTO prototype (id, type, name, keywords, description, data) VALUES
    (1, 'directory', 'Name',  'Keywords', 'Description', '');
INSERT INTO prototype (id, type, name, keywords, description, data) VALUES
    (2, 'article',   'Title', 'Keywords', 'Summary', 'Article text');
INSERT INTO prototype (id, type, name, keywords, description, data) VALUES
    (3, 'link',      'Name',  'Keywords', 'Description', 'URL');
