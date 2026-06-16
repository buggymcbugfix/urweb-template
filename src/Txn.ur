type id = int

datatype category =
	| RegularPocketMoney
	| Bonus
	| Withdrawal
	| Fine

val show_category =
	mkShow
		(
			fn cat =>
				case cat of
				| RegularPocketMoney => "RegularPocketMoney"
				| Bonus => "Bonus"
				| Withdrawal => "Withdrawal"
				| Fine => "Fine"
		)

val read_category : read category =
	mkRead'
		(
			fn str =>
				case str of
				| "RegularPocketMoney" => Some RegularPocketMoney
				| "Bonus" => Some Bonus
				| "Withdrawal" => Some Withdrawal
				| "Fine" => Some Fine
				| _ => None
		)
		"category"

con row =
	[
		UserId      = User.id,
		TxnSeq       = id,
		Timestamp   = time,
		Delta       = Money.ty,
		Balance     = Money.ty,
		Category    = serialized category,
		Description = string,
	]

table tbl : row
	PRIMARY KEY (UserId, TxnSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser userId =
	queryL
		(
			SELECT
				T.TxnSeq AS TxnSeq,
				T.Timestamp AS Timestamp,
				T.Delta AS Delta,
				T.Balance AS Balance,
				T.Category AS Category,
				T.Description AS Description
			FROM tbl AS T
			WHERE T.UserId = {[userId]}
			ORDER BY T.Timestamp DESC
		)
