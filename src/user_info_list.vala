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
	private HBox db;
	private Label homepage;
	
	private HSeparator desc_sep;
	
	FullStatus? full_status = null;
	
	private string username_text = "<b><big>(%s) @%s</big></b>";
	private string followers_text = _("Followers:  <b>%s</b>");
	private string friends_text = _("Friends:  <b>%s</b>");
	private string statuses_text = _("Statuses:  <b>%s</b>");
	private string homepage_text = _("Web:  <a href='%s'>%s</a>");
	
	public UserInfoList(Window _parent, Accounts _accounts, Template _template,
		int __items_count, Icon? _icon, string fname = "", string icon_name = "",
		string icon_desc = "") {
		
		base(_parent, _accounts, TimelineType.USER, _template, __items_count, 
			_icon, fname, icon_name, icon_desc);
		
		accounts.active_changed.connect(() => {
			set_empty();
		});
		
		gui_setup();
		
		set_empty();
	}
	
	private void gui_setup() {
		var pb = new VBox(false, 0);
		userpic = new Image.from_file(Config.USERPIC_PATH);
		userpic.set_size_request(48, 48);
		pb.pack_start(userpic, false, false, 0);
		
		var up = new VBox(false, 0);
		username = new Label("");
		
		var fb = new HBox(false, 0);
		follow = new CheckButton.with_label(_("follow"));
		fb.pack_end(follow, false, false, 0);
		
		up.pack_start(username, false, false, 2);
		up.pack_start(fb, false, false, 0);
		
		var sb = new VBox(false, 0);
		
		var fo = new HBox(false, 0);
		followers = new Label("");
		fo.pack_start(followers, false, false, 5);
		var fr = new HBox(false, 0);
		friends = new Label("");
		fr.pack_start(friends, false, false, 5);
		var st = new HBox(false, 0);
		statuses = new Label("");
		st.pack_start(statuses, false, false, 5);
		
		var ub = new HBox(false, 0);
		homepage = new Label("");
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
		
		db = new HBox(false, 0);
		desc = new TextView();
		desc.set_wrap_mode(Gtk.WrapMode.WORD);
		desc.set_sensitive(false);
		db.pack_start(desc, true, true, 5);
		
		vbox.pack_start(db, false, false, 5);
		
		desc_sep = new HSeparator();
		
		vbox.pack_start(desc_sep, false, false, 0);
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
	
	/* get data about following */
	private void update_following() {
		bool follow_him = false;
		
		try {
			follow_him = api.check_friendship(full_status.user_screen_name, true);
		} catch(RestError e) {
			//TODO
			
			return;
		}
		
		full_status.following = follow_him;
		follow.active = follow_him;
		follow.set_sensitive(true);
	}
	
	/* get user full info and his timeline */
	public void show_user(string screen_name) {
		act.activate();
		set_empty();
		start_screen();
		
		full_status = new FullStatus();
		full_status.user_screen_name = screen_name;
		
		try {
			lst = api.get_timeline(_items_count, full_status, "");
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		refresh_info();
		
		if(lst.size > 0) {
			refresh();
			update_following();
		}
		else
			set_empty(false);
	}
	
	/* set info about user */
	private void refresh_info() {
		//follow.set_sensitive(true);
		followers.set_markup(followers_text.printf(full_status.followers));
		friends.set_markup(friends_text.printf(full_status.friends));
		statuses.set_markup(statuses_text.printf(full_status.statuses));
		
		if(full_status.url != "") {
			homepage.set_markup(homepage_text.printf(full_status.url, full_status.url));
			homepage.show();
		} else {
			homepage.hide();
		}
		
		username.set_markup(username_text.printf(full_status.user_name,
			full_status.user_screen_name));
		
		//warning(full_status.following.to_string());
		//follow.active = full_status.following;
		
		if(full_status.desc != "") {
			desc.buffer.text = full_status.desc;
			db.show();
			desc_sep.show();
		} else {
			db.hide();
			desc_sep.hide();
		}
			
	}
	
	/* clear all data */
	public override void set_empty(bool full = true) {
		if(full) {
			full_status = null;
			follow.set_sensitive(false);
			followers.set_markup(followers_text.printf("-"));
			friends.set_markup(friends_text.printf("-"));
			statuses.set_markup(statuses_text.printf("-"));
			homepage.hide();
		
			username.set_markup(username_text.printf("John Doe", "john_doe"));
		
			desc.buffer.text = """The name "John Doe" is used as a placeholder name in a legal action, case or discussion for a male party, whose true identity is unknown or must be withheld for legal reasons.""";
		}
		
		lst.clear();
		last_focused = 0;
		update_content(template.generate_message(_("Empty")));
	}
}
