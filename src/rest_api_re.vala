using Gee;
using Soup;
using Xml;
using TimeUtils;

namespace RestAPI {

public class RestAPIRe : RestAPIAbstract {
	
	public override ArrayList<Status> get_direct(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		return null;
	}
	
	public override ArrayList<Status> get_timeline(int count = 0,
		string since_id = "", string max_id = "") throws RestError, ParseError {
		return null;
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
