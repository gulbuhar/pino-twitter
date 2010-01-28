using Gtk;
using Soup;
using Xml;
using RestAPI;

public class UserpicImage : Image {
	
	private Cache cache;
	
	weak Thread thread_1;
	RestAPIRe api;
	
	public UserpicImage(Cache _cache, RestAPIRe _api) {
		base;
		cache = _cache;
		api = _api;
	}
	
	public void update() {
		
		if (!Thread.supported()) {
			error("Cannot run without threads.");
			return;
		}
		
		try {
			thread_1 = Thread.create(get_userpic, false);
		} catch(ThreadError ex) {
			warning("Error: %s\n",ex.message);
			return;
        }
	}
	
	private void *get_userpic() {
		string req_url = api.get_urls().user.printf(api.auth_data.login);
		var session = new SessionSync();
		var message = new Message("GET", req_url);
		
		session.send_message(message);
		
		string url = parse_userpic_url(message.response_body.data);
		string path = cache.get_or_download(url, Cache.Method.SYNC, true);
		
		set_from_file(path);
		
		return null;
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
