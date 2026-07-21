(* The transaction sequence for a given user *)
type userSeq

datatype category =
	| PocketMoney (* regular pocket money *)
	| Bonus (* kiddo went above and beyond and earned themselves some extra bees *)
	| Withdrawal (* cash taken out, e.g. "dad give me 5, no not that, money. i want to buy something from the shop." *)
	| Deposit (* cash paid in *)
	| Fine (* kiddo wilfully did something they knew they shouldn't have and I want to dissuade them from repeating *)
	| Adjustment (* e.g. for opening balance or when we made a mistake somewhere *)
	| TransferOut (* e.g. dad bought something *)
	| TransferIn (* e.g. paid for something for dad *)

val show_category : show category

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

val getForUser :
	User.id ->
	transaction
		(
			list
				$[
					TxnUserSeq  = userSeq,
					Timestamp   = time,
					Delta       = Money.delta,
					Balance     = Money.ty,
					Category    = serialized category,
					Description = string,
				]
		)
