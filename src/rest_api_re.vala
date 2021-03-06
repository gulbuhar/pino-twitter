/* rest_api_re.vala
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

using Gee;
using Soup;
using Auth;
using Xml;
using TimeUtils;

namespace RestAPI {

public class RestAPIRe : RestAPIAbstract {
	
	public RestAPIRe(Account? _account) {
		base(_account);
	}
	
	public RestUrls get_urls() {
		return urls;
	}
	
	/* send new dm */
	public void send_dm(string user, string text) throws RestError {
		if(account == null)
			no_account();
		
		string req_url = urls.direct_new();
		
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("screen_name", user);
		map.insert("text", text);
		
		if(account != null && account.service == "identi.ca") //client name for identi.ca
			map.insert("source", Config.APPNAME);
		
		make_request(req_url, "POST", map);
	}
	
	/* post new status */
	public Status update_status(string text,
		string reply_id = "") throws RestError, ParseError {
		
		if(account == null)
			no_account();
		
		string req_url = urls.status_update();
		
		var map = new HashTable<string, string>(str_hash, str_equal);
		map.insert("status", text);
		
		if(account != null && account.service == "identi.ca") //client name for identi.ca
			map.insert("source", Config.APPNAME);
		
		if(reply_id != "")
			map.insert("in_reply_to_status_id", reply_id);
		
		string data = make_request(req_url, "POST", map);

		var result = parse_status(data);

		return result;
	}
	
	private Status parse_status(string data) throws ParseError {
		Status status = new Status();
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		if(xmlDoc == null)
			throw new ParseError.CODE("Invalid XML data");
		
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
					status.created_at_s = iter->get_content();
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
}

}
