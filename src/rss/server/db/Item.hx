package rss.server.db;

import sys.db.Types;

@:id(id)
class Item extends sys.db.Object {
	var id:SId;
	public var link:String;
	public var descr:String;
	public var title:String;
	public var pubDate:String;

	@:relation(source_id)
	public var source:Feed;
	public var timestamp:Float;
	public var read:Bool;

	public static function create(link:String, descr:String, title:String, pubDate:String, source:Feed) {
		var match = manager.search($link == link && $descr == descr && $title == title && $pubDate == pubDate && $source == source);
		if (match.isEmpty()) {
			var item = new Item();
			item.link = link;
			item.descr = descr;
			item.title = title;
			item.pubDate = pubDate;
			item.source = source;
			item.timestamp = Date.now().getTime();
			item.read = false;
			item.insert();
			trace("new item ", source);
			return item;
		}
		else {
			return match.first();
		}
	}

	public static function markAsRead(id:SId, ?value:Bool=true) {
		var match = manager.search($id == id);
		if (!match.isEmpty()) { 
			var item = match.first();
			item.read = value;
			item.update();
		}
	}

	public static function get(link:String, descr:String, title:String, pubDate:String, source:Feed) {
		return manager.search($link == link && $descr == descr && $title == title && $pubDate == pubDate && $source == source).first();
	}

}
