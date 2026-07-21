PRAGMA foreign_keys = ON;

INSERT INTO User_tbl
	(UserId , Username) VALUES
	(     1 , 'Huey'  ),
	(     2 , 'Dewey' ),
	(     3 , 'Louie' )
;

INSERT INTO Txn_tbl
	(UserId , TxnUserSeq , EffectiveDate , Timestamp         , Delta  , Balance , Category     , Description           ) VALUES
	(     1 ,          1 , '2026-06-01'  , CURRENT_TIMESTAMP ,  10000 ,   10000 , 'Adjustment' , 'Opening balance'     ),
	(     1 ,          2 , '2026-06-02'  , CURRENT_TIMESTAMP ,   1000 ,   11000 , 'Bonus'      , 'Chores'              ),
	(     1 ,          3 , '2026-06-03'  , CURRENT_TIMESTAMP , -  395 ,   10605 , 'Withdrawal' , 'Wants to buy a comic'),
	(     2 ,          1 , '2026-06-01'  , CURRENT_TIMESTAMP ,   1000 ,    1000 , 'Adjustment' , 'Opening balance'     ),
	(     3 ,          1 , '2026-06-01'  , CURRENT_TIMESTAMP ,   1000 ,    1000 , 'Adjustment' , 'Opening balance'     )
;
