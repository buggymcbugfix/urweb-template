type id

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

val getForUser :
	User.id ->
	transaction
		(
			list
				$[
					TxnSeq       = id,
					Timestamp   = time,
					Delta       = Money.ty,
					Balance     = Money.ty,
					Category    = serialized category,
					Description = string,
				]
		)
