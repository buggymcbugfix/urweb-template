CREATE TABLE Txn_tbl(
	UserId integer NOT NULL,
	UserTxnSeq integer NOT NULL,
	Timestamp text NOT NULL,
	EffectiveDate text NOT NULL,
	Delta integer NOT NULL,
	Balance integer NOT NULL,
	Category text NOT NULL,
	Description text NOT NULL,

	CONSTRAINT txn_tbl_pkey PRIMARY KEY (txnId),
	CONSTRAINT txn_tbl_Fk_UserId
	FOREIGN KEY (userId) REFERENCES user_tbl (userId)
)
;
