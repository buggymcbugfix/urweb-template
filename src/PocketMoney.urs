table weeklyAmount :
	[
		UserId = User.id,
		Amount = Money.ty,
		Starting = Date.ty,
	]
	PRIMARY KEY UserId

val collect : User.id -> transaction unit
