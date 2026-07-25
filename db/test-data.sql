PRAGMA foreign_keys = ON;

INSERT INTO User_tbl
	(UserId , Username) VALUES
	(     1 , 'Huey'  ),
	(     2 , 'Dewey' ),
	(     3 , 'Louie' )
;

CREATE VIEW Txn_vw AS
	SELECT UserId, EffectiveDate, Delta, Category, Description
	FROM Txn_tbl
;

CREATE TRIGGER Txn_vw_insert
INSTEAD OF
INSERT ON Txn_vw
BEGIN
	INSERT INTO Txn_tbl
		(UserId    , UserTxnSeq                                                                      , EffectiveDate    , Timestamp        , Delta    , Balance                                                                                                                                                          , Category    , Description     ) VALUES
		(NEW.UserId, COALESCE((SELECT MAX(UserTxnSeq) + 1 FROM Txn_tbl WHERE UserId = NEW.UserId), 1), NEW.EffectiveDate, CURRENT_TIMESTAMP, NEW.Delta, COALESCE((SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = (SELECT MAX(UserTxnSeq) FROM Txn_tbl WHERE UserId = NEW.UserId)), 0) + New.Delta, NEW.Category, NEW.Description )
	;
END
;

INSERT INTO Txn_vw
	(UserId , EffectiveDate , Delta  , Category     , Description ) VALUES
	(     1 , '2026-06-01'  ,  10000 , 'Adjustment' , 'Opening balance' ),
	(     1 , '2026-06-02'  ,   1000 , 'Bonus'      , 'Chores' ),
	(     1 , '2026-06-03'  , -  395 , 'Withdrawal' , 'Wants to buy a comic'),
	(     2 , '2026-06-01'  ,   1000 , 'Adjustment' , 'Opening balance' )
;

DROP VIEW Txn_vw
;

INSERT INTO PocketMoney_weeklyAmount
	(UserId, Amount, Starting    ) VALUES
	(     1,    500, '2025-12-12'),
	(     2,    500, '2025-12-12')
;
