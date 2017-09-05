async function addFeed () {
	var url = "index.php?new=" + encodeURIComponent(document.getElementById("new").value);
	var xhr = new XMLHttpRequest();
	xhr.open("GET", url, true);
	xhr.onload = function (e) {
	  if (xhr.readyState === 4) {
		if (xhr.status === 200) {
			var resp = xhr.responseText;
			console.log(resp);
			if (resp != "") {
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
				if (resp == id+" is read\n") {
					document.getElementById("item-"+id).classList.add("read");
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