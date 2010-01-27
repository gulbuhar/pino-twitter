using Gee;
using Soup;
using Xml;
using TimeUtils;

namespace RestAPI {

public class RestAPIRe : RestAPIAbstract {
	
	public RestAPIRe(IRestUrls _urls, AuthData _auth_data) {
		base(_urls, _auth_data);
	}
	
	public override ArrayList<Status> get_direct(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		return null;
	}
	
	public override ArrayList<Status> get_timeline(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		return null;
	}
	
	/* post new status */
	public Status update_status(string text,
		string reply_id = "") throws RestError, ParseError {
		
		string req_url = urls.status_update;
		
		var map = new HashTable<string, string>(null, null);
		map.insert("status", text);
		if(reply_id != "")
			map.insert("in_reply_to_status_id", reply_id);
		
		string data = make_request(req_url, "POST", map);
		
		return parse_status(data);
	}
	
	private Status parse_status(string data) {
		Status status = new Status();
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		string result = "";
		
		//changing locale to C
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		
		Xml.Node* iter;
		for(iter = rootNode->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;
			
			switch(iter->name) {
				case "id":
					status.id = iter->get_content();
					break;
				
				case "created_at":
					status.created_at = str_to_time(iter->get_content());
					break;
				
				case "text":
					status.text = iter->get_content();
					break;
				    			
				case "in_reply_to_screen_name":
					status.to_user = iter->get_content();
					break;
				
				case "in_reply_to_status_id":
					status.to_status_id = iter->get_content();
					break;
				
				case "retweeted_status":
					status.is_retweet = true;
					break;
				
				case "user":
				    Xml.Node *iter_user;
				    
					for(iter_user = iter->children->next; iter_user != null; iter_user = iter_user->next) {
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
				    } delete iter_user;			
					break;
			} delete iter;
		}
		
		//back to the normal locale
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		
		return status;
	}
	
	/* return user's userpic url */
	public string get_userpic_url() throws RestError, ParseError {
		string req_url = urls.user.printf(auth_data.login);
		
		string data = make_request(req_url, "GET");
		
		return parse_userpic_url(data);
	}
	
	private string parse_userpic_url(string data) {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		Xml.Node* rootNode = xmlDoc->get_root_element();
		
		string result = "";
		
		Xml.Node* iter;
		for(iter = rootNode->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;
			if(iter->name == "profile_image_url") {
				result = iter->get_content();
				break;
			}
		} delete iter;
		
		return result;
	}
}

}
