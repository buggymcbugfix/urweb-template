PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

CREATE TABLE Date_faux (
    Today text NOT NULL
);

CREATE TABLE User_tbl (
    UserId integer NOT NULL,
    Username text NOT NULL,
    CONSTRAINT User_tbl_pkey PRIMARY KEY (UserId),
    CONSTRAINT User_tbl_Uq_Username UNIQUE (Username)
);

CREATE TABLE Txn_tbl (
    UserId integer NOT NULL,
    UserTxnSeq integer NOT NULL,
    Timestamp text NOT NULL,
    EffectiveDate text NOT NULL,
    Delta integer NOT NULL,
    Balance integer NOT NULL,
    Category text NOT NULL,
    Description text NOT NULL,
    CONSTRAINT Txn_tbl_pkey PRIMARY KEY (UserTxnSeq, UserId),
    CONSTRAINT Txn_tbl_Fk_UserId FOREIGN KEY (UserId) REFERENCES User_tbl (UserId)
);

CREATE TABLE PocketMoney_weeklyAmount (
    UserId integer NOT NULL,
    Amount integer NOT NULL,
    Starting text NOT NULL,
    CONSTRAINT PocketMoney_weeklyAmount_pkey PRIMARY KEY (Starting, UserId)
);

