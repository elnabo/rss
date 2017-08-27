package rss.server.db;

import sys.db.Types;

@:id(id)
class Feed extends sys.db.Object {
	var id:SId;
	public var link:String;
	public var descr:String;
	public var title:String;

	public static function create(link:String, descr:String, title:String) {
		var match = Feed.manager.search($link == link);
		if (match.isEmpty()) {
			var feed = new Feed();
			feed.link = link;
			feed.descr = descr;
			feed.title = title;
			feed.insert();
			trace("New feed added: ", title, link);
			return feed;
		}
		else {
			return match.first();
		}
	}

	public static function all() : List<Feed> {
		return manager.all();
	}

	public static function get(link:String) {
		return Feed.manager.search($link == link).first();
	}
}
