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
	
	private Image userpic;
	private Label username;
	private CheckButton follow;
	
	private Label followers;
	private Label friends;
	private Label statuses;
	
	private TextView desc;
	private Label homepage;
	
	FullStatus full_status;
	
	private string username_text = "<b><big>(%s) @%s</big></b>";
	private string followers_text = _("Followers:  %s");
	private string friends_text = _("Friends:  %s");
	private string statuses_text = _("Statuses:  %s");
	private string homepage_text = _("Web:  <a href='%s'>%s</a>");
	
	public UserInfoList(Window _parent, Accounts _accounts, Template _template,
		int __items_count, Icon? _icon, string fname = "", string icon_name = "",
		string icon_desc = "") {
		
		base(_parent, _accounts, TimelineType.USER, _template, __items_count, 
			_icon, fname, icon_name, icon_desc);
		
		gui_setup();
	}
	
	private void gui_setup() {
		var pb = new VBox(false, 0);
		userpic = new Image.from_file(Config.USERPIC_PATH);
		userpic.set_size_request(48, 48);
		pb.pack_start(userpic, false, false, 0);
		
		var up = new VBox(false, 0);
		username = new Label("");
		username.set_markup(username_text.printf("John Doe", "john_doe"));
		
		var fb = new HBox(false, 0);
		follow = new CheckButton.with_label(_("follow"));
		fb.pack_end(follow, false, false, 0);
		
		up.pack_start(username, false, false, 2);
		up.pack_start(fb, false, false, 0);
		
		var sb = new VBox(false, 0);
		
		var fo = new HBox(false, 0);
		followers = new Label("");
		followers.set_markup(followers_text.printf("-"));
		fo.pack_start(followers, false, false, 5);
		var fr = new HBox(false, 0);
		friends = new Label("");
		friends.set_markup(friends_text.printf("-"));
		fr.pack_start(friends, false, false, 5);
		var st = new HBox(false, 0);
		statuses = new Label("");
		statuses.set_markup(statuses_text.printf("-"));
		st.pack_start(statuses, false, false, 5);
		
		var ub = new HBox(false, 0);
		homepage = new Label("");
		homepage.set_markup("Web:  <a href='http://google.com'>http://google.com</a>");
		ub.pack_start(homepage, false, false, 5);
		
		sb.pack_start(fo, false, false, 2);
		sb.pack_start(fr, false, false, 0);
		sb.pack_start(st, false, false, 0);
		sb.pack_start(ub, false, false, 0);
		
		var uh = new HBox(false, 0);
		uh.pack_end(pb, false, false, 0);
		uh.pack_end(up, false, false, 0);
		uh.pack_start(sb, false, false, 0);
		
		vbox.pack_start(uh, false, false, 5);
		vbox.pack_start(new HSeparator(), false, false, 0);
		
		var db = new HBox(false, 0);
		desc = new TextView();
		desc.set_wrap_mode(Gtk.WrapMode.WORD);
		desc.set_sensitive(false);
		desc.buffer.text = "oказалось, что бывают hd вебкамеры для мака http://bit.ly/2LeIy ну что, видео-т как #bobuk предложил?";
		db.pack_start(desc, true, true, 5);
		
		vbox.pack_start(db, false, false, 5);
		vbox.pack_start(new HSeparator(), false, false, 0);
	}
	
	/* get older statuses */
	protected override void get_older() {
		if(lst.size < 1)
			return;
		
		more.set_enabled(false);
		
		ArrayList<RestAPI.Status> result;
		string max_id = lst.get(lst.size - 1).id;
		
		try {
			result = api.get_timeline(_items_count, null, "", max_id);
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
	
	/* get user full info and his timeline */
	public void show_user(string screen_name) {
		act.activate();
		set_empty();
		
		full_status = new FullStatus();
		full_status.user_screen_name = screen_name;
		
		try {
			lst = api.get_timeline(_items_count, full_status, "");
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		refresh();
		
		warning(full_status.user_screen_name);
	}
}
