type userSeq = int

datatype category =
	| PocketMoney (* regular pocket money *)
	| Bonus (* kiddo went above and beyond and earned themselves some extra bees *)
	| Withdrawal (* cash taken out, e.g. "Papa give me 5, please. No not that, money. I want to buy something from the shop." *)
	| Deposit (* cash paid in *)
	| Fine (* kiddo wilfully did something they knew they shouldn't have and I want to dissuade them from repeating *)
	| Adjustment (* e.g. for opening balance or if we need to correct a previously made mistake *)
	| TransferOut (* e.g. I bought something for kiddo *)
	| TransferIn (* e.g. kiddo paid for something for dad *)

val show_category = mkShow (fn (x : category) => unsafeSerializedToString (serialize x))

con row =
	[
		UserId      = User.id,
		TxnUserSeq  = userSeq,
		Timestamp   = time,
		Delta       = Money.delta,
		Balance     = Money.ty,
		Category    = serialized category,
		Description = string,
	]

table tbl : row
	PRIMARY KEY (UserId, TxnUserSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser userId =
	queryL
		(
			SELECT
				T.TxnUserSeq AS TxnUserSeq,
				T.Timestamp AS Timestamp,
				T.Delta AS Delta,
				T.Balance AS Balance,
				T.Category AS Category,
				T.Description AS Description
			FROM tbl AS T
			WHERE T.UserId = {[userId]}
			ORDER BY T.Timestamp DESC
		)
