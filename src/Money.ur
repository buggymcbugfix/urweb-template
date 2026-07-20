type ty = int

fun padLeft (totalLen : int) (s : string) : string =
	if strlen s >= totalLen then
		s
	else
		padLeft totalLen ("0" ^ s)

fun groupThousands (sep : string) (s : string) : string =
	let
		val len = strlen s
	in
		if len <= 3 then
			s
		else
			groupThousands sep (String.substring s {Start = 0, Len = (len - 3)})
				^ sep
				^ String.substring s {Start = (len - 3), Len = 3}
	end

(* Formats an integer as a fixed-point decimal string, treating `n` as the
   value scaled by 10^decimalPlaces (e.g. decimalPlaces = 2: 12345 -> 123.45).
   `thousandsSep` is inserted every 3 digits of the integer part ("" to disable). *)
val intToDecimal (thousandsSep : string) (decimalPoint : string) (decimalPlaces : int) (n : int) : string =
	let
		val (str, isNegative) =
			case String.split (show n) #"-" of
			| None => (show n, False)
			| Some (_, str) => (str, True)

		val len = strlen str

		val absResultStr =
			if decimalPlaces <= 0 then
				groupThousands thousandsSep str
			else if len <= decimalPlaces then
				"0" ^ decimalPoint ^ padLeft decimalPlaces str
			else
				groupThousands thousandsSep (String.substring str {Start = 0, Len = (len - decimalPlaces)})
					^ decimalPoint
					^ String.substring str {Start = (len - decimalPlaces), Len = decimalPlaces}
		in
			if isNegative then "-" ^ absResultStr else absResultStr
	end

val fmt m =
	let
		val amt = intToDecimal Config.currencyThousandsSeparator Config.currencyDecimalSeparator 2 m

		val symbol = Config.currencySymbol
	in
		if Config.currencySymbolBeforeAmount then
			symbol ^ " " ^ amt
		else
			amt ^ " " ^ symbol
	end

val show_ty = mkShow (fn ty => fmt ty)

val testPage =
	srcN <- source "";
	return
		<xml>
			<body>
				<ctextbox source={srcN}/>
				<dyn signal={
					n <- signal srcN;
					case @@read [int] _ n of
					| None => return <xml/>
					| Some n => return <xml>{[fmt n]}</xml>
				}/>
			</body>
		</xml>
