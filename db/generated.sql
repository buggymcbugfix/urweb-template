PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE User_tbl (
    UserId integer NOT NULL,
    Username text NOT NULL,
    CONSTRAINT User_tbl_pkey PRIMARY KEY (UserId),
    CONSTRAINT User_tbl_Uq_Username UNIQUE (Username)
);

