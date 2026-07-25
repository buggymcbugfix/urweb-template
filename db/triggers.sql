CREATE TRIGGER Txn_tbl_validate_UserTxnSeq
BEFORE INSERT ON Txn_tbl
WHEN
		NEW.UserTxnSeq
	<>
		COALESCE(
			(SELECT MAX(UserTxnSeq) + 1 FROM Txn_tbl WHERE UserId = NEW.UserId),
			1
		)
BEGIN
	SELECT RAISE(ABORT, 'invalid UserTxnSeq sequence: ' || NEW.UserTxnSeq);
END;

CREATE TRIGGER Txn_tbl_validate_Balance
BEFORE INSERT ON Txn_tbl
FOR EACH ROW
WHEN
		(SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = NEW.UserTxnSeq - 1) + NEW.Delta
	<>
		NEW.Balance
BEGIN
	SELECT RAISE(ABORT, 'balance_prev + delta ≠ balance_new (' || (SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = NEW.UserTxnSeq - 1) || ' + ' || NEW.Delta || ' = ' || ((SELECT Balance FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = NEW.UserTxnSeq - 1) + New.Delta) || ' ≠ ' || NEW.Balance || ')');
END;

CREATE TRIGGER Txn_tbl_arrow_of_time
BEFORE INSERT ON Txn_tbl
FOR EACH ROW
WHEN
		NEW.Timestamp
	<
		(SELECT Timestamp FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = NEW.UserTxnSeq - 1)
BEGIN
	SELECT RAISE(ABORT, 'NEW.Timestamp (' || NEW.Timestamp || ') is before previous transaction''s timestamp (' || (SELECT Timestamp FROM Txn_tbl WHERE UserId = NEW.UserId AND UserTxnSeq = NEW.UserTxnSeq - 1) || ')');
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
