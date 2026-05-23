type id
val show_id : show id

con row =
	[
		UserId = id,
		Username = string,
	]

val getAll : transaction (list $row)
