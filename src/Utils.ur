
val fetchInto [a] (src : source a) (txn : transaction a) =
	<xml>
		<active code={
			spawn
				(
					data <- rpc txn;
					set src data
				);
			return <xml/>
		}/>
	</xml>

(* val deriveShow [t :: Type] = mkShow (fn (x : t) => unsafeSerializedToString (serialize x)) *)

val show_serialized [a] (_ : show a) = mkShow (fn x => show (deserialize x))

val sqlize
		[ts ::: {Type}]
		(fl : folder ts)
		(sql_injs : $(map sql_injectable ts))
		(r : $ts)
	:
		$(map (fn t => sql_exp [] [] [] t) ts)
	=
		@foldR2
			[sql_injectable]
			[ident]
			[fn rs => $(map (fn t => sql_exp [] [] [] t) rs)]
			(
				fn [nm ::_] [t ::_] [r ::_] [[nm] ~ r] inj value acc =>
					{nm = @sql_inject inj value} ++ acc
			)
			{}
			fl
			sql_injs
			r
