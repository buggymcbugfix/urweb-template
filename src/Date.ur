type ty = string

val show = show_string

val parse str = Some str
	(* case readUtc (str ^ " 00:00:00") of
	| Some _ => Some str
	| None => None *)

val read = mkRead' parse "Date.ty"

val ord = ord_string

val sql_injectable = sql_string

val sql_maxable = sql_maxable_string

val fromTime = timef "%Y-%m-%d"

val toTime d =
	fromDatetime
		(readError (substring d 0 4))
		(readError (substring d 5 2) - 1)
		(readError (substring d 8 2))
		0
		0
		0

table faux : [Today = ty]

val today = oneRowE1 (SELECT faux.Today AS Today FROM faux)

val unixEpoch = "1970-01-01"

val addDays n d =
	fromTime
		(
			fromDatetime
				(readError (substring d 0 4))
				(readError (substring d 5 2) - 1)
				(readError (substring d 8 2) + n)
				0
				0
				0
		)

(* Broken because `readUtc` doesn't have a JS version *)
(* val testPage =
	srcDate <- source "2026-05-04";
	srcN <- source "2";
	return
		<xml>
			<body>
				<ctextbox source={srcDate}/>
				<ctextbox source={srcN}/>
				<dyn signal={
					date <- signal srcDate;
					n <- signal srcN;
					case (Basis.read date, Basis.read n) of
					| (Some date, Some n) => return <xml>{[addDays n date]}</xml>
					| _ => return <xml/>
				}/>
			</body>
		</xml> *)
