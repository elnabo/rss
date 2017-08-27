package rss.server;

import rss.server.db.Feed;
import rss.server.db.Item;

class Main {

	static var db(default, never) = "rss.db";

	public static function main() {
		initDB();
		// new RSS("http://www.lemonde.fr/rss/une.xml");
		for (feed in Feed.all()) {
			new RSS(feed.link);
			trace(feed.link);
		}
	}

	public static function initDB() {
		try {
			sys.db.Manager.cnx = sys.db.Sqlite.open(db);
			if ( !sys.db.TableCreate.exists(Feed.manager) ){
				sys.db.TableCreate.create(Feed.manager);
			}
			if ( !sys.db.TableCreate.exists(Item.manager) ){
				sys.db.TableCreate.create(Item.manager);
			}
		}
		catch (e:Dynamic) {
			trace(e);
			Sys.exit(-1);
		}
	}
}
