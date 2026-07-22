table weeklyAmount :
	[
		UserId = User.id,
		Amount = Money.ty,
		Starting = Date.ty,
	]
	PRIMARY KEY UserId

val getLatestPocketMoneyTxn userId : transaction (option Date.ty) =
	let
		val txn = Txn.tbl
	in
		latest <-
			oneOrNoRowsE1
				(
					SELECT MAX(txn.EffectiveDate) AS LatestEffectiveDate
					FROM txn
					WHERE txn.Category = {[serialize Txn.PocketMoney]}
						AND txn.UserId = {[userId]}
				);
		case latest of
		| Some (Some latest) => return (Some latest)
		| _ => return None
	end

val collectNextFromGivenDate r =
	today <- Date.today;
	nextPayday <- return (Date.addDays 7 r.LatestEffectiveDate);
	if nextPayday <= today then
		amt <-
			oneOrNoRowsE1
				(
					SELECT weeklyAmount.Amount AS Amount
					FROM weeklyAmount
					WHERE weeklyAmount.Starting <= {[nextPayday]}
					ORDER BY weeklyAmount.Starting ASC
					LIMIT 1
				);
		(
			case amt of
			| None => return False
			| Some amt =>
				Txn.create
					{
						UserId = r.UserId,
						EffectiveDate = nextPayday,
						Delta = Money.toDelta amt,
						Category = Txn.PocketMoney,
						Description = ""
					};
				return True
		)
	else
		return False

val collectNext userId =
	latest <- getLatestPocketMoneyTxn userId;
	case latest of
	| Some latest => collectNextFromGivenDate {UserId = userId, LatestEffectiveDate = latest}
	| None =>
		startDate <-
			oneOrNoRowsE1
				(
					SELECT weeklyAmount.Starting AS Starting
					FROM weeklyAmount
					WHERE weeklyAmount.UserId = {[userId]}
					ORDER BY weeklyAmount.Starting ASC
					LIMIT 1
				);
		case startDate of
		| Some startDate =>
			collectNextFromGivenDate {UserId = userId, LatestEffectiveDate = startDate}
		| None =>
			error <xml>No weekly amount configured for user {[userId]}</xml>

fun collect userId =
	res <- collectNext userId;
	case res of
	| True => collect userId
	| False => return {}
