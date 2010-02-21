/* user_info_list.vala
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

using Gtk;
using Gee;
using Auth;
using RestAPI;

public class UserInfoList : TimelineListAbstract {
	
	public UserInfoList(Window _parent, Accounts _accounts, Template _template,
		int __items_count, Icon? _icon, string fname = "", string icon_name = "",
		string icon_desc = "") {
		
		base(_parent, _accounts, TimelineType.HOME, _template, __items_count, 
			_icon, fname, icon_name, icon_desc);
	}
	
	/* get older statuses */
	protected override void get_older() {
		if(lst.size < 1)
			return;
		
		more.set_enabled(false);
		
		ArrayList<RestAPI.Status> result;
		string max_id = lst.get(lst.size - 1).id;
		
		try {
			result = api.get_timeline(_items_count, "", max_id);
		} catch(RestError e) {
			more.set_enabled(true);
			updating_error(e.message);
			return;
		}
		
		if(result.size < 2) {
			more.set_enabled(true);
			return;
		}
		
		lst.add_all(result.slice(1, result.size -1));
		refresh();
		finish_update(); //send signal
		
		more.set_enabled(true);
	}
	
	/* refresh timeline */
	public override void refresh() {
		if(lst.size == 0)
			set_empty();
		else
			update_content(template.generate_timeline(lst, last_focused));
	}
}
