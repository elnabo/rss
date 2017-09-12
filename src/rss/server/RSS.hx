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
	public function new(link:String, ?parseItem:Bool=true, ?asRead:Bool=false, ?log:Bool=true) {
		create(link, parseItem, asRead, log);
	}

	private function create(link:String, parseItem:Bool, asRead:Bool, log:Bool) {
		try {
			var http = new haxe.Http(link);
			http.addHeader("user-agent", "Mozilla/5.0");
			http.addHeader("Accept:", "text/html");
			http.onData= function (data:String) {
				var headers = http.responseHeaders;
				if (headers.exists("Location") && headers.get("Location") != link) {
					create(headers.get("Location"), parseItem, asRead, log);
					return;
				}
				if (headers.exists("Content-Encoding")) {
					switch (headers.get("Content-Encoding")) {
						case "gzip":
							var input = new haxe.io.BytesInput(haxe.io.Bytes.ofString(data));
							var reader = new format.gz.Reader(input);
							data = reader.read().data.toString();
						default:
					}
				}
				try {
					var xml = new Fast(Parser.parse(data, false));
					var channel:Fast;

					if (xml.nodes.rss.length > 0) {
						var rss = xml.nodes.rss.first();
						channel = rss.nodes.channel.first();
					}
					else {
						channel = xml.nodes.feed.first();
					}
					
					var cdescr = firstInnerData(channel.nodes.descr);
					var ctitle = innerData(channel.nodes.title.first());

					feed = Feed.create(link, cdescr, ctitle,log);

					created = feed.justCreated;
					if (!parseItem) {
						return;
					}

					var list = channel.nodes.item;
					if (list.length == 0) {
						list = channel.nodes.entry;
					}
					for (item in list) {
						var ititle = innerData(item.nodes.title.first());
						var idescr = innerData(item.nodes.descr.first());
						if (idescr == "") { idescr = innerData(item.nodes.description.first()); }
						var ilink = innerLinkData(item.nodes.link.first());
						var ipubDate = innerData(item.nodes.pubDate.first());
						Item.create(ilink, idescr, ititle, ipubDate, feed, asRead, log);
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

	public function firstInnerData(list:List<Fast>) {
		return (list.length == 0) ? innerData(list.first()) : "";
	}

	public function innerData(node:Fast) {
		return (node == null) ? "" : node.innerData.trim();
	}

	public function innerLinkData(node:Fast) {
		if (node == null) {
			return "";
		}

		if (node.has.href) {
			return node.att.href.trim();
		}

		try {
			return node.innerData.trim();
		}
		catch (e:Dynamic) {
			return "";
		}
	}
}
