con row =
	[
		UserId = User.id,
		Balance = Money.ty,
	]

table tbl : row
	PRIMARY KEY UserId,
	CONSTRAINT Fk_UserId FOREIGN KEY UserId REFERENCES {{User.tbl}}(UserId)

val getAll =
	queryL
		(
			SELECT
				B.Balance AS Balance,
				U.Username AS Username
			FROM tbl AS B
			JOIN {{User.tbl}} AS U
				ON B.UserId = U.UserId
			ORDER BY U.UserId
		)
