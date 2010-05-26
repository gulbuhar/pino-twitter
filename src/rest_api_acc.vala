/* rest_api_acc.vala
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

using Auth;
using Xml;

namespace RestAPI {

public class RestAPIAcc : RestAPIAbstract {
	
	public RestAPIAcc(Account? _account) {
		base(_account);
	}
	
	public RestUrls get_urls() {
		return urls;
	}
	
	/* get userpic url of a current user */
	public string? get_userpic_url() throws RestError, ParseError {
		if(account == null)
			return null;
		
		string req_url = urls.user().printf(account.login);
		string data = make_request(req_url, "GET",
			new HashTable<string, string>(str_hash, str_equal), false);

		var result = parse_userpic_url(data);

		return result;
	}
	
	private string parse_userpic_url(string data) throws ParseError {
		Xml.Doc* xmlDoc = Parser.parse_memory(data, (int)data.size());
		if(xmlDoc == null)
			throw new ParseError.CODE("Invalid XML data");
		
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
