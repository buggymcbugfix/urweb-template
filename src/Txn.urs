(* The transaction sequence for a given user *)
type userSeq

datatype category =
	| RegularPocketMoney
	| Bonus
	| Withdrawal
	| Fine

val show_category : show category

val read_category : read category

con row =
	[
		UserId      = User.id,
		TxnUserSeq  = userSeq,
		Timestamp   = time,
		Delta       = Money.ty,
		Balance     = Money.ty,
		Category    = serialized category,
		Description = string,
	]

table tbl : row
	PRIMARY KEY (UserId, TxnUserSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser :
	User.id ->
	transaction
		(
			list
				$[
					TxnUserSeq  = userSeq,
					Timestamp   = time,
					Delta       = Money.ty,
					Balance     = Money.ty,
					Category    = serialized category,
					Description = string,
				]
		)
