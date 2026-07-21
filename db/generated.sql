PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE date_faux(
    today text NOT NULL);

CREATE TABLE user_tbl(
    userid integer NOT NULL,
    username text NOT NULL,
    CONSTRAINT user_tbl_pkey PRIMARY KEY (userId),
    CONSTRAINT user_tbl_Uq_Username UNIQUE (username));

CREATE TABLE txn_tbl(
    userid integer NOT NULL,
    txnuserseq integer NOT NULL,
    timestamp text NOT NULL,
    effectivedate text NOT NULL,
    delta integer NOT NULL,
    balance integer NOT NULL,
    category text NOT NULL,
    description text NOT NULL,
    CONSTRAINT txn_tbl_pkey PRIMARY KEY (txnUserSeq, userId),
    CONSTRAINT txn_tbl_Fk_UserId
     FOREIGN KEY (userId) REFERENCES user_tbl (userId));

