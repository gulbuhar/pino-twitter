/* rest_urls.vala
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

namespace RestAPI {

public class RestUrls : Object {
	
	private ServiceType stype;
	
	
	private string prefix = "";
	
	public string home() {
		return prefix + "statuses/home_timeline.xml";
	}
	
	public string status_update() {
		return prefix + "statuses/update.xml";
	}
	
	public string destroy_status() {
		return prefix + "statuses/destroy/%s.xml";
	}
	
	public string destroy_direct() {
		return prefix + "direct_messages/destroy/%s.xml";
	}
	
	public string direct_new() {
		return prefix + "direct_messages/new.xml";
	}
	
	public string mentions() {
		return prefix + "statuses/mentions.xml";
	}
	
	public string direct_in() {
		return prefix + "direct_messages.xml";
	}
		
	public string user() {
		return prefix + "users/show/%s.xml";
	}
	
	public string friendship() {
		return prefix + "friendships/show.xml";
	}
	
	public string status() {
		return prefix + "statuses/show/%s.xml";
	}
	
	public string users_timeline() {
		return prefix + "statuses/user_timeline/%s.xml";
	}
	
	public string follow_create() {
		return prefix + "friendships/create/%s.xml";
	}
	
	public string follow_destroy() {
		return prefix + "friendships/destroy/%s.xml";
	}
	
	public RestUrls(ServiceType _stype, string _prefix = "") {
		set_prefix(_stype, _prefix);
	}
	
	public void set_prefix(ServiceType _stype, string _prefix = "") {
		stype = _stype;
		
		switch(_stype) {
			case ServiceType.TWITTER:
				prefix = "http://api.twitter.com/";
				break;
			
			case ServiceType.IDENTICA:
				prefix = "http://identi.ca/api/";
				break;
			
			case ServiceType.UNKNOWN:
				prefix = _prefix;
				break;
		}
	}
}

}
