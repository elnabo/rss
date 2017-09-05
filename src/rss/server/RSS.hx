package rss.server;

import haxe.xml.Parser;
import haxe.xml.Fast;

import rss.db.Feed;
import rss.db.Item;

using StringTools;

class RSS {
	public var created:Bool = false;
	public var feed:Feed;

	// public function new(data:String, ?creation:Bool=false) {
	public function new(link:String, ?parseItem:Bool=true, ?log:Bool=true) {
		try {
			var http = new haxe.Http(link);
			http.addHeader("user-agent", "Mozilla/5.0");
			http.addHeader("Accept:", "text/html");
			http.onData= function (data:String) {
				try {
					var xml = new Fast(Parser.parse(data, false));
					var rss = xml.nodes.rss.first();
					var channel = rss.nodes.channel.first();

					var cdescr = innerData(channel.nodes.descr.first());
					var ctitle = innerData(channel.nodes.title.first());
					feed = Feed.create(link, cdescr, ctitle,log);

					created = feed.justCreated;
					if (!parseItem) {
						return;
					}

					for (item in channel.nodes.item) {
						var ititle = innerData(item.nodes.title.first());
						var idescr = innerData(item.nodes.descr.first());
						if (idescr == "") { idescr = innerData(item.nodes.description.first()); }
						var ilink = innerData(item.nodes.link.first());
						var ipubDate = innerData(item.nodes.pubDate.first());
						Item.create(ilink, idescr, ititle, ipubDate, feed, log);
					}
				}
				catch (e:Dynamic) {
					if (log) {
						trace(e);
					}
					created = false;
				}
			};
			http.request();
		}
		catch (e:Dynamic) {
			if (log) {
				trace(e);
			}
			created = false;
		}
	}

	public function innerData(node:Fast) {
		return (node == null) ? "" : node.innerData.trim();
	}
}
