CREATE TRIGGER Txn_tbl_validate_TxnUserSeq
BEFORE INSERT ON Txn_tbl
WHEN
		NEW.TxnUserSeq
	<>
		COALESCE(
			(SELECT MAX(TxnUserSeq) + 1 FROM Txn_tbl WHERE UserId = NEW.UserId),
			1
		)
BEGIN
	SELECT RAISE(ABORT, 'invalid TxnUserSeq sequence: ' || NEW.TxnUserSeq);
END;

CREATE TRIGGER Txn_tbl_validate_Balance
BEFORE INSERT ON Txn_tbl
FOR EACH ROW
WHEN
		NEW.Balance - NEW.Delta
	<>
		(SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND TxnUserSeq = NEW.TxnUserSeq - 1)
BEGIN
	SELECT RAISE(ABORT, 'NEW.Balance (' || NEW.Balance || ') - NEW.Delta (' || NEW.Delta || ') does not match previous balance (' || (SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND TxnUserSeq = NEW.TxnUserSeq - 1) || ')');
END;

CREATE TRIGGER Txn_tbl_arrow_of_time
BEFORE INSERT ON Txn_tbl
FOR EACH ROW
WHEN
		NEW.Timestamp
	<
		(SELECT Timestamp FROM Txn_tbl WHERE UserId = NEW.UserId AND TxnUserSeq = NEW.TxnUserSeq - 1)
BEGIN
	SELECT RAISE(ABORT, 'NEW.Timestamp (' || NEW.Timestamp || ') is before previous transaction''s timestamp (' || (SELECT Timestamp FROM Txn_tbl WHERE UserId = NEW.UserId AND TxnUserSeq = NEW.TxnUserSeq - 1) || ')');
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
