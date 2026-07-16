PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE User_tbl (
    UserId integer NOT NULL,
    Username text NOT NULL,
    CONSTRAINT User_tbl_pkey PRIMARY KEY (UserId),
    CONSTRAINT User_tbl_Uq_Username UNIQUE (Username)
);

CREATE TABLE Txn_tbl (
    UserId integer NOT NULL,
    TxnUserSeq integer NOT NULL,
    Timestamp text NOT NULL,
    Delta integer NOT NULL,
    Balance integer NOT NULL,
    Category text NOT NULL,
    Description text NOT NULL,
    CONSTRAINT Txn_tbl_pkey PRIMARY KEY (TxnUserSeq, UserId),
    CONSTRAINT Txn_tbl_Fk_UserId FOREIGN KEY (UserId) REFERENCES User_tbl (UserId)
);

