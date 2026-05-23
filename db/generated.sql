PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE user_tbl(
    userid integer NOT NULL,
    username text NOT NULL,
    CONSTRAINT user_tbl_pkey PRIMARY KEY (userId),
    CONSTRAINT user_tbl_Uq_Username UNIQUE (username));

