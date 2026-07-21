
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
