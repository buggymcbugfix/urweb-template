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
		UserId        = User.id,
		TxnUserSeq    = userSeq,
		Timestamp     = time,
		EffectiveDate = Date.ty,
		Delta         = Money.Delta.ty,
		Balance       = Money.ty,
		Category      = serialized category,
		Description   = string,
	]

table tbl : row
	PRIMARY KEY (UserId, TxnUserSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser userId =
	queryL1
		(
			SELECT *
			FROM tbl
			WHERE tbl.UserId = {[userId]}
			ORDER BY tbl.TxnUserSeq DESC
		)

val create r =
	latestTxn <- oneOrNoRows1 (SELECT tbl.TxnUserSeq, tbl.Balance FROM tbl WHERE tbl.UserId = {[r.UserId]});
	case latestTxn of
	| None =>
		dml
			(
				insert tbl
					{
						UserId        = (SQL {[r.UserId]}),
						TxnUserSeq    = (SQL 1),
						Timestamp     = (SQL CURRENT_TIMESTAMP),
						EffectiveDate = (SQL {[r.EffectiveDate]}),
						Delta         = (SQL {[r.Delta]}),
						Balance       = (SQL {[Money.fromDelta r.Delta]}),
						Category      = (SQL {[serialize r.Category]}),
						Description   = (SQL {[r.Description]})
					}
			)
	| Some latestTxn =>
		dml
			(
				insert tbl
					{
						UserId        = (SQL {[r.UserId]}),
						TxnUserSeq    = (SQL {[latestTxn.TxnUserSeq + 1]}),
						Timestamp     = (SQL CURRENT_TIMESTAMP),
						EffectiveDate = (SQL {[r.EffectiveDate]}),
						Delta         = (SQL {[r.Delta]}),
						Balance       = (SQL {[Money.applyDelta r.Delta latestTxn.Balance]}),
						Category      = (SQL {[serialize r.Category]}),
						Description   = (SQL {[r.Description]})
					}
			)
