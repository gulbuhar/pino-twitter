using Soup;
using Gee;
using RestAPI;

public class RestAPITimeline : RestAPIAbstract {
	
	public RestAPITimeline(IRestUrls _urls, TimelineType _timeline_type) {
		base(_urls, _timeline_type);
		
		var map = new HashTable<string, string>(null, null);
		/*map.insert("status","@troorl ola!");
		map.insert("in_reply_to_status_id", "7493402160");
		make_request(urls.status_update, "POST", map);
		
		map.insert("count","20");
		map.insert("since_id", "7809451600");
		make_request(urls.home, "GET", map);
		*/
	}
	
	public override ArrayList<Status> get_timeline(int count,
		string since_id) throws RestError {
		string req_url = "";
		
		switch(timeline_type) {
			case TimelineType.HOME:
				req_url = urls.home;
				break;
			case TimelineType.MENTIONS:
				req_url = urls.mentions;
				break;
		}
		
		var map = new HashTable<string, string>(null, null);
		map.insert("count", count.to_string());
		if(since_id != "")
			map.insert("since_id", since_id);
		
		string data = make_request(req_url, "GET", map);
		warning(data);
		var l = new ArrayList<Status>();
		return l;
	}
}