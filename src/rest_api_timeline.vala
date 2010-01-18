using Soup;
using Gee;
using Xml;

namespace RestAPI {

public class RestAPITimeline : RestAPIAbstract {
	
	private TimelineType timeline_type;
	
	public RestAPITimeline(IRestUrls _urls, AuthData _auth_data,
		TimelineType _timeline_type) {
		base(_urls, _auth_data);
		this.timeline_type = _timeline_type;
	}
	
	/* for timelines (home, mentions, public etc.) */
	public override ArrayList<Status> get_timeline(int count = 20,
		string since_id = "") throws RestError, ParseError {
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
		
		return parse_timeline(data);
	}
	
	/* parsing timeline */
	private ArrayList<Status> parse_timeline(string data) throws ParseError {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		ArrayList<Status> lst = new ArrayList<Status>();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			if(iter->name == "status") {
				
				if(iter->children != null) {
		        	Status status = new Status();
		        	Xml.Node *iter_in;
				    
				    for(iter_in = iter->children->next; iter_in != null; iter_in = iter_in->next) {
				    	
				    	if(iter_in->is_text() != 1) {
				    		
				    		switch(iter_in->name) {
				    			case "id":
				    				status.id = iter_in->get_content();
				    				break;
				    			
				    			case "created_at":
				    				var tmpTime = Time();
				    				tmpTime.strptime(iter_in->get_content(), "%a %b %d %T +0000 %Y");
				    				var tt = tmpTime.mktime();
				    				var tmp = Time.local(tt);
				    				int delta = tz_delta(tmp);
				    				int int_t = (int)tt + delta * 3600;
				    				
				    				status.created_at = Time.local((time_t)int_t);
				    				break;
				    			
				    			case "text":
				    				status.text = iter_in->get_content();
				    				break;
				    			
				    			case "in_reply_to_screen_name":
				    				status.to_user = iter_in->get_content();
				    				break;
				    			
				    			case "in_reply_to_status_id":
				    				status.to_status_id = iter_in->get_content();
				    				break;
				    			
				    			case "retweeted_status":
				    				status.is_retweet = true;
				    				
				    				Xml.Node *iter_retweet;
				    				
				    				for(iter_retweet = iter_in->children->next; iter_retweet != null; iter_retweet = iter_retweet->next) {
				    					switch(iter_retweet->name) {
				    						case "user":
				    							Xml.Node *iter_re_user;
				    							
				    							for(iter_re_user = iter_retweet->children->next; iter_re_user != null; iter_re_user = iter_re_user->next) {
				    								switch(iter_re_user->name) {
				    									case "name":
				    										status.re_user_name = iter_re_user->get_content();
				    										break;
				    									
				    									case "screen_name":
				    										status.re_user_screen_name = iter_re_user->get_content();
				    										break;
				    									
				    									case "profile_image_url":
				    										status.re_user_avatar = iter_re_user->get_content();
				    										break;
				    								}
				    							}
				    							delete iter_re_user;
				    							break;
				    						
				    						case "text":
				    							if(iter_retweet->get_content().substring(0, 3) != "\n  " ) {
				    								status.re_text = iter_retweet->get_content();
				    							}
				    							break;
				    					}
				    				}
				    				
				    				delete iter_retweet;
				    				break;
				    			
				    			case "user":
				    				Xml.Node *iter_user;
				    				
									for(iter_user = iter_in->children->next; iter_user != null; iter_user = iter_user->next) {
										switch(iter_user->name) {
											case "id":
				    							break;
				    						
				    						case "name":
				    							status.user_name = iter_user->get_content();
				    							break;
				    						
				    						case "screen_name":
				    							status.user_screen_name = iter_user->get_content();
				    							break;
				    						
				    						case "profile_image_url":
				    							status.user_avatar = iter_user->get_content();
				    							break;
				    					}
				    				}
				    				delete iter_user;
				    				break;
				    		}
				    	}
				    }
				    delete iter_in;
				    
				    lst.add(status);
				    
				}
		    }
		    delete iter; //memory leak was here >:3
		}
		
		return lst;
	}
	
	/* delete status with some id */
	public void destroy_status(string status_id) throws RestError {
		string req_url = urls.destroy_status.printf(status_id);
		make_request(req_url, "DELETE");
	}
}

}