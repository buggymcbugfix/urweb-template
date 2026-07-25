type userSeq = int

structure Category = struct
	datatype ty =
		| PocketMoney (* regular pocket money *)
		| Bonus (* kiddo went above and beyond and earned themselves some extra bees *)
		| Withdrawal (* cash taken out, e.g. "Papa give me 5, please. No not that, money. I want to buy something from the shop." *)
		| Deposit (* cash paid in *)
		| Fine (* kiddo wilfully did something they knew they shouldn't have and I want to dissuade them from repeating *)
		| Adjustment (* e.g. for opening balance or if we need to correct a previously made mistake *)
		| Reimbursement (* e.g. kiddo paid for something for dad or gave some money to dad (at dad's request) *)

	val enumerate =
		PocketMoney ::
		Bonus ::
		Withdrawal ::
		Deposit ::
		Fine ::
		Adjustment ::
		Reimbursement ::
			[]

	val show = mkShow (fn (x : ty) => unsafeSerializedToString (serialize x))
end


con row =
	[
		UserId        = User.id,
		UserTxnSeq    = userSeq,
		Timestamp     = time,
		EffectiveDate = Date.ty,
		Delta         = Money.Delta.ty,
		Balance       = Money.ty,
		Category      = serialized Category.ty,
		Description   = string,
	]

table tbl : row
	PRIMARY KEY (UserId, UserTxnSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser userId =
	queryL1
		(
			SELECT *
			FROM tbl
			WHERE tbl.UserId = {[userId]}
			ORDER BY tbl.UserTxnSeq DESC
		)

val create r =
	prevUserTxnSeq <-
		oneRowE1
			(
				SELECT MAX(tbl.UserTxnSeq) AS PrevUserTxnSeq
				FROM tbl 
				WHERE tbl.UserId = {[r.UserId]}
			);
	newBalance <-
		(
			case prevUserTxnSeq of
			| None => return (Money.fromDelta r.Delta)
			| Some prevUserTxnSeq =>
				prevBalance <-
					oneRowE1
						(
							SELECT tbl.Balance AS Balance
							FROM tbl 
							WHERE tbl.UserTxnSeq = {[prevUserTxnSeq]}
								AND tbl.UserId = {[r.UserId]}
						);
				return (Money.applyDelta r.Delta prevBalance)
		);
	dml
		(
			insert tbl
				{
					UserId        = (SQL {[r.UserId]}),
					UserTxnSeq    = (SQL {[case prevUserTxnSeq of None => 1 | Some i => i + 1]}),
					Timestamp     = (SQL CURRENT_TIMESTAMP),
					EffectiveDate = (SQL {[r.EffectiveDate]}),
					Delta         = (SQL {[r.Delta]}),
					Balance       = (SQL {[newBalance]}),
					Category      = (SQL {[serialize r.Category]}),
					Description   = (SQL {[r.Description]})
				}
		)
