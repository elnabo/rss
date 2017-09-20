function addFeed () {
	var url = "index.php?new=" + encodeURIComponent(document.getElementById("new").value);
	var xhr = new XMLHttpRequest();
	xhr.open("GET", url, true);
	xhr.onload = function (e) {
	  if (xhr.readyState === 4) {
		if (xhr.status === 200) {
			var resp = xhr.responseText;
			console.log(resp);
			if (resp != "Error" && resp != "Exists") {
				resp = resp.split(" ");
				var id = resp.pop();
				var name = resp.join(" ");
				addToFeedList(id, name);
			}

		} else {
			console.error(xhr.statusText);
		}
	  }
	};
	xhr.onerror = function (e) {
		console.error(xhr.statusText);
	};
	xhr.send(null); 
}

function addToFeedList(id, name) {
	var list = document.getElementById("feedlist");
	var li = document.createElement("li");
	var a = document.createElement("a");
	a.setAttribute("href",'index.php?feed='+id);
	a.innerText = name;
	li.appendChild(a);
	list.appendChild(li);
}

setInterval(function(){update();},1000*60*5);
function update() {
	updateCount();
	updateFeed();
}

function markAsRead(id) {
	var url = "index.php?mark="+id;
	var xhr = new XMLHttpRequest();

	var element = document.getElementById("mark-"+id);
	element.setAttribute("onclick", "");

	xhr.open("GET", url, true);
	xhr.onload = function (e) {
	  if (xhr.readyState === 4) {
			if (xhr.status === 200) {
				var resp = xhr.responseText;
				if (resp == id+" is read") {
					var e = document.getElementById("item-"+id);
					e.classList.add("read");
					var feed = e.classList.item(0);
					var count = document.getElementById("unreadcount-"+feed);
					var c = parseInt(count.innerText) - 1;

					var global = document.getElementById("unreadcount-0");
					var g = parseInt(global.innerText) - 1;

					if (c == NaN || c == 0) {
						count.innerText = "";
					}
					else {
						count.innerText = ""+c;
					}

					if (g == NaN || g == 0) {
						global.innerText = "";
					}
					else {
						global.innerText = ""+g;
					}
				}
				else {
					element.setAttribute("onclick", "markAsRead("+id+")");
				}
			} 
			else {
				element.setAttribute("onclick", "markAsRead("+id+")");
			}
		}
	};
	xhr.onerror = function (e) {
		console.error(xhr.statusText);
	};
	xhr.send(null); 
}

function markAllAsRead(id) {
	var url = "index.php?markAll="+id;
	var xhr = new XMLHttpRequest();

	xhr.open("GET", url, true);
	xhr.onload = function (e) {
	  if (xhr.readyState === 4) {
			if (xhr.status === 200) {
				var resp = xhr.responseText;
				if (resp == "OK") {
					updateCount();
					return;
				}
				else {
					console.log(resp);
					alert("Unable to read all");
				}
			}
		}
		else {
			alert("Unable to read all");
		}
	};
	xhr.onerror = function (e) {
		console.error(xhr.statusText);
	};
	xhr.send(null); 
}

function updateFeed() {
	if (document.getElementById("top-left") != null) {
		return;
	}
	var article = document.getElementsByTagName("article")[0];
	var feed = article.id.substr(5);
	var children = article.childNodes;
	var mostRecent = -1;
	var ul = null;
	for (var i=0; i<children.length; i++) {
		if (children[i].nodeName.toLowerCase() == "ul") {
			for (var j=0; j<children[i].childNodes.length; j++) {
				if (children[i].children[j].nodeName.toLowerCase() == "li") {
					ul = children[i];
					mostRecent = children[i].children[j].id.substr(5);
					break;
				}
			}
		}
	}

	var url = "index.php?feed="+feed+"&newSince="+mostRecent;
	var xhr = new XMLHttpRequest();	
	xhr.open("GET", url, true);
	xhr.onload = function (e) {
		if (xhr.readyState === 4) {
			if (xhr.status === 200) {
				var resp = xhr.responseText;
				ul.innerHTML = resp + ul.innerHTML;
			} 
			else {
			}
		}
	};
	xhr.onerror = function (e) {
		console.error(xhr.statusText);
	};
	xhr.send(null); 
}

function updateCount() {
	var url = "index.php?count";
	var xhr = new XMLHttpRequest();
	xhr.open("GET", url, true);
	xhr.onload = function (e) {
	  if (xhr.readyState === 4) {
			if (xhr.status === 200) {
				var lines = xhr.responseText.split("\n");
				var feeds = lines[0].split(" ");
				var counts = lines[1].split(" ");
				for (var i=0; i<feeds.length; i++) {
					console.log("unreadcount-"+feeds[i]);
					var counter = document.getElementById("unreadcount-"+feeds[i]);
					var current = parseInt(counter.innerText);
					if (current == NaN) { current = 0; }

					var newcount = parseInt(counts[i]);
					if (newcount == NaN) { newcount = 0; }

					var diff = newcount - current;
					console.log(newcount + " " + current + " " + diff);
					if (diff > 0 && feeds[i] != 0) {
						notif(document.getElementById("feed-"+feeds[i]), diff.toString());
					}
					counter.innerHTML = (newcount == 0) ? "" : counts[i];

				}

			} else {
				console.error(xhr.statusText);
			}
	  }
	};
	xhr.onerror = function (e) {
	  console.error(xhr.statusText);
	};
	xhr.send(null); 
}

function notif (element, count) {
	if (!("Notification" in window)) {
		return;
	}

	if (Notification.permission === "granted") {
		new Notification(count + " new item(s) in "+element.innerText);
	}

	else if (Notification.permission !== 'denied') {
		Notification.requestPermission(function (permission) {
			if(!('permission' in Notification)) {
				Notification.permission = permission;
			}
			if (permission === "granted") {
				new Notification(count + "new item(s) in "+element.innerText);
			}
		});
	}
}