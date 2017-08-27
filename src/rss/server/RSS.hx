package rss.server;

import haxe.xml.Parser;
import haxe.xml.Fast;

import rss.server.db.Feed;
import rss.server.db.Item;

using StringTools;

class RSS {
	// public function new(data:String, ?creation:Bool=false) {
	public function new(link:String) {
		try {
			var data = haxe.Http.requestUrl(link);
			var xml = new Fast(Parser.parse(data, false));
			var rss = xml.nodes.rss.first();
			var channel = rss.nodes.channel.first();

			var feed:Feed;
			var cdescr = innerData(channel.nodes.descr.first());
			var ctitle = innerData(channel.nodes.title.first());
			feed = Feed.create(link, cdescr, ctitle);

			for (item in channel.nodes.item) {
				var ititle = innerData(item.nodes.title.first());
				var idescr = innerData(item.nodes.descr.first());
				var ilink = innerData(item.nodes.link.first());
				var ipubDate = innerData(item.nodes.pubDate.first());
				Item.create(ilink, idescr, ititle, ipubDate, feed);
			}
		}
		catch (e:Dynamic) {
			trace(e);
		}
	}

	public function innerData(node:Fast) {
		return (node == null) ? "" : node.innerData.trim();
	}
}
