val mkPage (x : xbody) =
	<xml>
		<head>
			<link rel="stylesheet" type="text/css" href="/css/main.css"/>
		</head>
		<body>
			{x}
		</body>
	</xml>

val returnMkPage = return <<< mkPage

val hello name = returnMkPage <xml>Hello, {[name]}!</xml>

val renderTransactionTr r =
	<xml>
		<tr class={if Money.Delta.isNegative r.Delta then Class.negative else Class.positive}>
			<td>{[timef "%Y-%m-%d (%a)" (Date.toTime r.EffectiveDate)]}</td>
			<td class={Class.right_aligned}>{[r.Delta]}</td>
			<td class={Class.right_aligned}>{[r.Balance]}</td>
			<td>{[r.Category]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	PocketMoney.collect userId;
	user <- User.get userId;
	txns <- Txn.getForUser userId;
	scTxns <- source txns;
	returnMkPage
		<xml>
			<h1>Transactions for {[user.Username]}</h1>
			<table>
				<tr>
					<th>Date</th>
					<th>Delta</th>
					<th>Balance</th>
					<th>Category</th>
					<th>Description</th>
				</tr>
				<dyn signal={
					txns <- signal scTxns;
					return (List.mapX renderTransactionTr txns)
				}/>
			</table>
			(* <button onclick={fn _ => rpc (PocketMoney.collect userId)}>Collect</button> *)
		</xml>

val renderUserRow r =
	<xml>
		<li>
			<a link={myTransactions r.UserId}>{[r.Username]}</a>
		</li>
	</xml>

val users =
	(users : list $User.row) <- User.getAll;
	returnMkPage
		<xml>
			<ul>
				{List.mapX renderUserRow users}
			</ul>
		</xml>

val index =
	returnMkPage
		<xml>
			<h1>Bank of Dad</h1>
			<ul>
				<li><a link={hello "World"}>hello world</a></li>
				<li><a link={users}>list of all users</a></li>
			</ul>
			<span style="display:none">@GIT_REV@</span>
		</xml>
