PRAGMA foreign_keys = ON;
-- A comment that mentions DROP TABLE must not count.
CREATE TABLE installs (id TEXT PRIMARY KEY, note TEXT DEFAULT 'DROP TABLE x');
/* block comment: DROP COLUMN y */
