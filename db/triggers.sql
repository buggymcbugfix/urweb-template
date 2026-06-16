CREATE TRIGGER Txn_tbl_validate_TxnSeq
BEFORE INSERT ON Txn_tbl
WHEN
		NEW.TxnSeq
	<>
		COALESCE(
			(SELECT MAX(TxnSeq) + 1 FROM Txn_tbl WHERE UserId = NEW.UserId),
			1
		)
BEGIN
	SELECT RAISE(ABORT, 'invalid TxnSeq sequence: ' || NEW.TxnSeq);
END;

CREATE TRIGGER Txn_tbl_validate_Balance
BEFORE INSERT ON Txn_tbl
FOR EACH ROW
WHEN
		NEW.Balance - NEW.Delta
	<>
		(SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND TxnSeq = NEW.TxnSeq - 1)
BEGIN
	SELECT RAISE(ABORT, 'NEW.Balance - NEW.Delta does not match previous balance');
END;

CREATE TRIGGER Txn_tbl_no_update
BEFORE UPDATE ON Txn_tbl
BEGIN
	SELECT RAISE(ABORT, 'Txn_tbl is immutable');
END;

CREATE TRIGGER Txn_tbl_no_delete
BEFORE DELETE ON Txn_tbl
BEGIN
	SELECT RAISE(ABORT, 'Txn_tbl is immutable');
END;
