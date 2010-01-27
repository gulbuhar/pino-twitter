using Soup;
using Gee;
using Xml;
using TimeUtils;

namespace RestAPI {

public class RestAPIDirect : RestAPIAbstract {
	
	public 	RestAPIDirect(IRestUrls _urls, AuthData _auth_data) {
		base(_urls, _auth_data);
	}
	
	public override ArrayList<Status> get_timeline(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		return null;
	}
	
	/* destroy direct message */
	public override void destroy_status(string id) throws RestError {
		string req_url = urls.destroy_direct.printf(id);
		make_request(req_url, "DELETE");
	}
	
	/* get direct messages (inbox) */
	public override ArrayList<Status> get_direct(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		
		var map = new HashTable<string, string>(null, null);
		if(count != 0)
			map.insert("count", count.to_string());
		if(since_id != "")
			map.insert("since_id", since_id);
		if(max_id != "")
			map.insert("max_id", max_id);
		
		string data = make_request(urls.direct_in, "GET", map);
		
		return parse_direct(data);
	}
	
	/* parsing direct messages */
	private ArrayList<Status> parse_direct(string data) {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		ArrayList<Status> lst = new ArrayList<Status>();
		
		for(Xml.Node* iter = rootNode->children; iter != null; iter = iter->next) {
			if(iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			if(iter->name == "direct_message") {
				
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
				    				status.created_at = str_to_time(iter_in->get_content());
				    				break;
				    			
				    			case "text":
				    				status.text = iter_in->get_content();
				    				break;
				    			
				    			case "sender":
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
		
		
		//back to the normal locale
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		
		return lst;
	}
}

}
