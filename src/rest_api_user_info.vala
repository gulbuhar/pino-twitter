/* rest_api_user_info.vala
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
using Gee;
using Soup;

namespace RestAPI {

public class RestAPIUserInfo : RestAPITimeline {
	
	public RestAPIUserInfo(Account? _account) {
		base(_account, TimelineType.USER);
	}
	
	public override void follow_create(string screen_name) throws RestError {
		string req_url = urls.follow_create().printf(screen_name);
		make_request(req_url, "POST");
	}
	
	public override void follow_destroy(string screen_name) throws RestError {
		string req_url = urls.follow_destroy().printf(screen_name);
		make_request(req_url, "POST");
	}
}

}
