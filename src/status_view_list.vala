/* status_view_list.vala
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
using Auth;
using RestAPI;
using Gee;
using Xml;

public class StatusViewList : TimelineList {
	
	public StatusViewList(Window _parent, Accounts _accounts, Status status,
		Template _template) {
		
		base(_parent, _accounts, TimelineType.HOME, _template, 0, null);
		lst.add(status);
	}
	
	private override void get_older(){}
	
	public override ArrayList<Status>? update() {
		refresh();
		
		for(int i = 0; i < 6; i++) {
			if(lst.get(0).to_status_id == "")
				break;
			
			try {
				Status status = api.get_status(lst.get(0).to_status_id);
				lst.insert(0, status);
			} catch(RestError e) {
				updating_error(e.message);
				return lst;
			}
			
			refresh();
		}
		
		return lst;
	}
	
	public override void refresh() {
		if(lst.size == 0)
			set_empty();
		else
			update_content(template.generate_timeline(lst, last_focused));
	}
}
