PRAGMA foreign_keys = ON;

INSERT INTO User_tbl
	(UserId , Username) VALUES
	(     1 , 'Huey'  ),
	(     2 , 'Dewey' ),
	(     3 , 'Louie' )
;

INSERT INTO Txn_tbl
	(TxnUserSeq , Timestamp         , UserId , Delta , Balance , Category     , Description           ) VALUES
	(    1      , CURRENT_TIMESTAMP ,      1 ,  1000 ,    1000 , 'Bonus'      , 'Chores'              ),
	(    2      , CURRENT_TIMESTAMP ,      1 , - 395 ,     605 , 'Withdrawal' , 'Wants to buy a comic'),
	(    3      , CURRENT_TIMESTAMP ,      1 , -   2 ,     603 , 'Fine'       , 'Language (2 ×)'      )
;
