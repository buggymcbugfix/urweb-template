open Utils

val gitRev = return <xml><body>@GIT_REV@</body></xml>

val hello name = return <xml><body>Hello, {[name]}!</body></xml>

val renderUserTr r =
	<xml>
		<tr>
			<td>{[r.UserId]}</td>
			<td>{[r.Username]}</td>
		</tr>
	</xml>

val users =
	srcUsers <- source [];
	return
		<xml>
			<body>
				(* {fetchInto srcUsers User.getAll} *)
				<active code={
					spawn
						(
							data <- rpc User.getAll;
							set srcUsers data
						);
					return <xml/>
				}/>
				<table>
				<tr><th>ID</th><th>Username</th></tr>
				<dyn signal={
					users <- signal srcUsers;
					return (List.mapX renderUserTr users)
				}/>
				</table>
			</body>
		</xml>

val index =
	return
		<xml>
			<body>
				<ul>
					<li><a link={gitRev}>git hash</a></li>
					<li><a link={hello "World"}>hello world</a></li>
					<li><a link={users}>list of all users</a></li>
				</ul>
			</body>
		</xml>
