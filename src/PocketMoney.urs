table weeklyAmount :
	[
		UserId = User.id,
		Amount = Money.ty,
		Starting = Date.ty,
	]
	PRIMARY KEY (UserId, Starting)

val collect : User.id -> transaction unit
