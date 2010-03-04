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
	
	private Userpic userpic;
	private Label username;
	private CheckButton follow;
	
	private Label followers;
	private Label friends;
	private Label statuses;
	
	private TextView desc;
	private HBox db;
	private HBox uh;
	private Label homepage;
	
	private HSeparator first_sep;
	private HSeparator desc_sep;
	
	FullStatus? full_status = null;
	
	private string username_text = "<b><big>(%s) @%s</big></b>";
	private string followers_text = _("Followers:  <b>%s</b>");
	private string friends_text = _("Friends:  <b>%s</b>");
	private string statuses_text = _("Statuses:  <b>%s</b>");
	private string homepage_text;
	
	public signal void start_fetch();
	public signal void end_fetch();
	public signal void follow_event(string msg);
	
	public UserInfoList(Window _parent, Accounts _accounts, Template _template,
		int __items_count, Icon? _icon, string fname = "", string icon_name = "",
		string icon_desc = "") {
		
		base(_parent, _accounts, TimelineType.USER, _template, __items_count, 
			_icon, fname, icon_name, icon_desc);
		
		need_more_button = false;
		
		var acc = accounts.get_current_account();
		api = new RestAPIUserInfo(acc);
		
		homepage_text = _("Web:  <a href='%s'><span foreground='" + template.gtk_style.sl_color + "'>%s</span></a>");
		
		accounts.active_changed.connect(() => {
			set_empty();
		});
		
		gui_setup();
		
		set_empty();
	}
	
	private void gui_setup() {
		var pb = new VBox(false, 0);
		userpic = new Userpic(template.cache);
		userpic.set_size_request(48, 48);
		pb.pack_start(userpic, false, false, 0);
		
		var up = new VBox(false, 0);
		username = new Label("");
		
		var fb = new HBox(false, 0);
		follow = new CheckButton.with_label(_("follow"));
		follow.toggled.connect(follow_toggled);
		fb.pack_end(follow, false, false, 0);
		
		up.pack_start(username, false, false, 2);
		up.pack_start(fb, false, false, 0);
		
		VBox sb = new VBox(false, 0);
		
		var fo = new HBox(false, 0);
		followers = new Label("");
		fo.pack_start(followers, false, false, 8);
		var fr = new HBox(false, 0);
		friends = new Label("");
		fr.pack_start(friends, false, false, 8);
		var st = new HBox(false, 0);
		statuses = new Label("");
		st.pack_start(statuses, false, false, 8);
		
		var ub = new HBox(false, 0);
		homepage = new Label("");
		ub.pack_start(homepage, false, false, 8);
		
		sb.pack_start(fo, false, false, 2);
		sb.pack_start(fr, false, false, 0);
		sb.pack_start(st, false, false, 0);
		sb.pack_start(ub, false, false, 0);
		
		uh = new HBox(false, 0);
		uh.pack_end(pb, false, false, 8);
		uh.pack_end(up, false, false, 0);
		uh.pack_start(sb, false, false, 0);
		
		vbox.pack_start(uh, false, false, 8);
		first_sep = new HSeparator();
		vbox.pack_start(first_sep, false, false, 0);
		
		db = new HBox(false, 0);
		desc = new TextView();
		desc.set_wrap_mode(Gtk.WrapMode.WORD);
		desc.set_sensitive(false);
		db.pack_start(desc, true, true, 8);
		
		vbox.pack_start(db, false, false, 8);
		
		desc_sep = new HSeparator();
		
		vbox.pack_start(desc_sep, false, false, 0);
	}
	
	/* get older statuses */
	protected override void get_older() {
		//TODO
	}
	
	/* get data about following */
	private void update_following() {
		bool follow_him = false;
		
		try {
			follow_him = api.check_friendship(full_status.user_screen_name, true);
		} catch(RestError e) {
			updating_error(e.message);
			return;
		}
		
		full_status.following = follow_him;
		follow.active = follow_him;
		follow.set_sensitive(true);
	}
	
	/* get user full info and his timeline */
	public void show_user(string screen_name) {
		if(accounts.get_current_account().login == screen_name)
			return;
		
		act.activate();
		
		if(full_status != null && full_status.user_screen_name == screen_name)
			return;
		
		start_fetch(); //signal
		
		set_empty();
		start_screen();
		
		full_status = new FullStatus();
		full_status.user_screen_name = screen_name;
		
		try {
			lst = api.get_timeline(_items_count, full_status, "");
		} catch(RestError.CODE_404 e) {
			set_empty();
			updating_error(_("This user does not exist")); //signal
			
			return;
		} catch(RestError e) {
			set_empty();
			updating_error(e.message); //signal
			
			return;
		}
		
		refresh_info();
		
		if(lst.size > 0) {
			refresh();
			update_following();
		}
		else
			set_empty(false);
		
		end_fetch(); //signal
		
		more.set_sensitive(true);
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
		
		userpic.set_pic(full_status.user_avatar);
		
		uh.show();
		first_sep.show();
		
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
			userpic.set_default();
			full_status = null;
			follow.set_sensitive(false);
			followers.set_markup(followers_text.printf("-"));
			friends.set_markup(friends_text.printf("-"));
			statuses.set_markup(statuses_text.printf("-"));
			homepage.hide();
		
			username.set_markup(username_text.printf("-", "-"));
			
			db.hide();
			uh.hide();
			first_sep.hide();
			desc_sep.hide();
			desc.buffer.text = "";
		}
		
		more.set_sensitive(false);
		
		lst.clear();
		last_focused = 0;
		//update_content(template.generate_message(_("Empty")));
		update_content(template.generate_user_show_form());
	}
	
	/* follow/unfollow some user */
	private void follow_toggled() {
		//skip if this is initialization
		if(full_status != null && follow.active == full_status.following)
			return;
		
		follow.set_sensitive(false);
		
		if(follow.active) {
			try {
				api.follow_create(full_status.user_screen_name);
			} catch(RestError e) {
				updating_error(e.message);
				follow.active = full_status.following;
				follow.set_sensitive(true);
				return;
			}
		} else {
			try {
				api.follow_destroy(full_status.user_screen_name);
			} catch(RestError e) {
				updating_error(e.message);
				follow.active = full_status.following;
				follow.set_sensitive(true);
				return;
			}
		}
		
		full_status.following = follow.active;
		follow.set_sensitive(true);
		
		if(follow.active)
			follow_event(_("Now you follow this user")); //signal
		else
			follow_event(_("User was unfollowed")); //signal
	}
}
