style metadata

val mkPage (x : xbody) =
	rev <- getenv (blessEnvVar "GIT_REV");
	return
		<xml>
			<head>
				<link rel="stylesheet" type="text/css" href="/css/main.css"/>
			</head>
			<body>
				{x}
				<footer><span class={metadata}>{[rev]}</span></footer>
			</body>
		</xml>

val hello name = mkPage <xml>Hello, {[name]}!</xml>

val renderTransactionTr r =
	<xml>
		<tr>
			<td>{[r.EffectiveDate]}</td>
			<td>{[r.Delta]}</td>
			<td>{[r.Balance]}</td>
			<td>{[r.Category]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	user <- User.get userId;
	txns <- Txn.getForUser userId;
	mkPage
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
				{List.mapX renderTransactionTr txns}
			</table>
		</xml>

val renderUserRow r =
	<xml>
		<li>
			<a link={myTransactions r.UserId}>{[r.Username]}</a>
		</li>
	</xml>

val users =
	(users : list $User.row) <- User.getAll;
	mkPage
		<xml>
			<ul>
				{List.mapX renderUserRow users}
			</ul>
		</xml>

val index =
	mkPage
		<xml>
			<h1>Bank of Dad</h1>
			<ul>
				<li><a link={hello "World"}>hello world</a></li>
				<li><a link={users}>list of all users</a></li>
			</ul>
			<span style="display:none">@GIT_REV@</span>
		</xml>
