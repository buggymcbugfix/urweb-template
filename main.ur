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
		<tr>
			<td>{[r.Timestamp]}</td>
			<td>{[r.Delta]}</td>
			<td>{[r.Balance]}</td>
			<td>{[show (deserialize r.Category)]}</td>
			<td>{[r.Description]}</td>
		</tr>
	</xml>

val myTransactions userId =
	txns <- Txn.getForUser userId;
	returnMkPage
		<xml>
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
