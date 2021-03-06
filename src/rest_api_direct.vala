/* rest_api_direct.vala
 *
 * Copyright (C) 2009-2010  troorl
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	troorl <troorl@gmail.com>
 */

using Soup;
using Gee;
using Xml;
using Auth;
using TimeUtils;

namespace RestAPI {

public class RestAPIDirect : RestAPIAbstract {
	
	public 	RestAPIDirect(Account? _account) {
		base(_account);
	}
	
	/* destroy direct message */
	public override void destroy_status(string id) throws RestError {
		string req_url = urls.destroy_direct().printf(id);
		make_request(req_url, "DELETE");
	}
	
	/* get direct messages (inbox) */
	public override ArrayList<Status>? get_timeline(int count = 0, FullStatus? fstatus = null,
		string since_id = "",
		string max_id = "", bool sync = true) throws RestError, ParseError {
		
		if(account == null)
			no_account();
		
		var map = new HashTable<string, string>(str_hash, str_equal);
		if(count != 0)
			map.insert("count", count.to_string());
		if(since_id != "")
			map.insert("since_id", since_id);
		if(max_id != "")
			map.insert("max_id", max_id);
		
		string data = make_request(urls.direct_in(), "GET", map);

		var result = parse_direct(data);

		return result;
	}
	
	/* parsing direct messages */
	private ArrayList<Status> parse_direct(string data) throws ParseError {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		if(xmlDoc == null)
			throw new ParseError.CODE("Invalid XML data");
		
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
				    				status.created_at_s = iter_in->get_content();
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
