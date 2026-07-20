PRAGMA foreign_keys = ON;

INSERT INTO User_tbl
	(UserId , Username) VALUES
	(     1 , 'Huey'  ),
	(     2 , 'Dewey' ),
	(     3 , 'Louie' )
;

INSERT INTO Txn_tbl
	(TxnUserSeq , Timestamp         , UserId , Delta  , Balance , Category     , Description           ) VALUES
	(         1 , CURRENT_TIMESTAMP ,      1 ,  10000 ,   10000 , 'Adjustment' , 'Opening balance'     ),
	(         2 , CURRENT_TIMESTAMP ,      1 ,   1000 ,   11000 , 'Bonus'      , 'Chores'              ),
	(         3 , CURRENT_TIMESTAMP ,      1 , -  395 ,   10605 , 'Withdrawal' , 'Wants to buy a comic'),
	(         1 , CURRENT_TIMESTAMP ,      2 ,   1000 ,    1000 , 'Adjustment' , 'Opening balance'     ),
	(         1 , CURRENT_TIMESTAMP ,      3 ,   1000 ,    1000 , 'Adjustment' , 'Opening balance'     )
;
