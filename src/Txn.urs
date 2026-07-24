(* The transaction sequence for a given user *)
type userSeq

structure Category : sig
	datatype ty =
		| PocketMoney (* regular pocket money *)
		| Bonus (* kiddo went above and beyond and earned themselves some extra bees *)
		| Withdrawal (* cash taken out, e.g. "Papa give me 5, please. No not that, money. I want to buy something from the shop." *)
		| Deposit (* cash paid in *)
		| Fine (* kiddo wilfully did something they knew they shouldn't have and I want to dissuade them from repeating *)
		| Adjustment (* e.g. for opening balance or if we need to correct a previously made mistake *)
		| TransferOut (* e.g. I bought something for kiddo *)
		| TransferIn (* e.g. kiddo paid for something for dad or gave some money to dad (at dad's request) *)

	val enumerate : list ty

	val show : show ty
end

con row =
	[
		UserId        = User.id,
		TxnUserSeq    = userSeq,
		Timestamp     = time,
		EffectiveDate = Date.ty,
		Delta         = Money.Delta.ty,
		Balance       = Money.ty,
		Category      = serialized Category.ty,
		Description   = string,
	]

table tbl : row
	PRIMARY KEY (UserId, TxnUserSeq),
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getForUser : User.id -> transaction (list $row)

val create :
	{
		UserId        : User.id,
		EffectiveDate : Date.ty,
		Delta         : Money.Delta.ty,
		Category      : Category.ty,
		Description   : string,
	}
	-> transaction unit
