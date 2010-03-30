/* favorites_view_list.vala
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

public class FavoritesViewList : TimelineList {
	
	public FavoritesViewList(Window _parent, Accounts _accounts, Template _template) {
		base(_parent, _accounts, TimelineType.FAVORITES, _template, 0, null);
		
		//need_more_button = true; //no "more" button
	}
	
	//private override void get_older(){}
	
	public override ArrayList<Status>? update() {
		ArrayList<Status> result = null;
		string since_id = "";
		bool first_time = true;
		
		if(lst.size > 0) {
			since_id = lst.get(0).id;
			first_time = false;
		}
		
		try {
			result = api.get_timeline(_items_count, null, since_id);
		} catch(RestError e) {
			updating_error(e.message);
			return result;
		}
		
		warning("SIZE: %d", result.size);
		
		if(result.size > 0) { //if we got some statuses
			
			if(lst.size == 0) {
				lst.add_all(result);
			} else {
				int i = 0;
				foreach(Status status in result) { //insert statuses at the start of the list
					lst.insert(i, status);
					i++;
				}
			}
		}
		
		refresh(true);
		
		finish_update(); //send signal
		
		if(first_time)
			result.clear();
		
		return result;
	}
}
