/* re_tweet.vala
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

public class ReTweet : VBox {
	
	public static enum Style { CLASSIC, UNI, VIA }
	
	private static enum State { NEW, REPLY, DIRECT_REPLY, RETWEET }
	
	private State state;
	
	private RestAPIRe api;
	
	private TextView entry;
	public TextView text_entry {
		public get { return entry; }
	}
	
	public string text {
		public owned get
		{ return entry.buffer.text; }
		set
		{ entry.buffer.set_text(value, (int)value.size()); }
	}
	
	private Accounts accounts;
	
	private Image status_icon;
	private Label label;
	public Label user_label;
	
	public Action shortAct;
	
	private DmEntry direct_entry;
	private ToolButton close_btn;
	private Window parent;
	private Prefs prefs;
	private UrlShort url_short;
	private string reply_id = "";
	
	Regex nicks;
	Regex urls;
	Regex tags;
	
	SystemStyle gtk_style;
	
	public signal void start_update(string req_url);
	public signal void sending_data(string message);
	public signal void data_sent(string message);
	public signal void data_error_sent(string message);
	public signal void status_updated(Status status);
	
	public ReTweet(Window _parent, Prefs _prefs, Accounts _accounts, Cache cache, SystemStyle _gtk_style) {
		parent = _parent;
		prefs = _prefs;
		accounts = _accounts;
		gtk_style = _gtk_style;
		
		var acc = accounts.get_current_account();
		api = new RestAPIRe(acc);
		api.request.connect((req) => start_update(req));
		
		url_short = new UrlShort(prefs, api);
		
		shortAct = new Action("UrlShort", _("Shorten URLs..."), null, null);
		shortAct.set_sensitive(false);
		shortAct.activate.connect(() => {
			shortAct.set_sensitive(false);
			set_sensitive(false);
			sending_data(_("Shortening URLs...")); //signal
			
			string reply = url_short.shortit(text);
			
			if(reply != text)
				data_sent(_("URLs was shortened successfully")); //signal
			else
				data_sent(_("Nothing to shorten")); //signal
			
			text = reply;
			
			shortAct.set_sensitive(true);
			set_sensitive(true);
			
			parent.set_focus(entry);
		});
		
		//enable or disable shrten url action
		show.connect((event) => {
			shortAct.set_sensitive(true);
		});
		hide.connect((event) => {
			shortAct.set_sensitive(false);
		});
		
		//gui setup
		border_width = 0;
		set_homogeneous(false);
		set_spacing(2);
		
		var l_box = new HBox(false, 2);
		status_icon = new Image();
		user_label = new Label(_("New status:"));
		
		direct_entry = new DmEntry(api);
		
		label = new Label("<b>140</b>");
		label.set_use_markup(true);
		
		Image close_img = new Image();
		close_img.set_from_stock("gtk-close", IconSize.MENU);
		close_img.set_tooltip_text(_("Hide"));
		var event_close = new EventBox();
		event_close.add(close_img);
		event_close.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		event_close.button_press_event.connect((event) => {
			hide();
			return false;
		});
		
		l_box.pack_start(status_icon, false, false, 2);
		l_box.pack_start(user_label, false, false, 2);
		l_box.pack_start(direct_entry, false, false, 2);
		l_box.pack_end(event_close, false, false, 2);
		l_box.pack_end(label, false, false, 2);
		
		entry = new TextView();
		entry.set_size_request(-1, 60);
		entry.set_wrap_mode(Gtk.WrapMode.WORD);
		entry.key_press_event.connect(hide_or_send);
		entry.buffer.changed.connect(change);
		
		entry.buffer.create_tag("red_bg", "background", "#ffa4a4");
		entry.buffer.create_tag("url", "foreground", gtk_style.sl_color);
		entry.buffer.create_tag("nick", "weight", Pango.Weight.BOLD);
		entry.buffer.create_tag("tag", "foreground", gtk_style.sl_color,
			"weight", Pango.Weight.BOLD);
		
		prefs.enableSpellChanged.connect(spellEnabling);
		spellEnabling();
		
		
		nicks = new Regex("(^|\\s)@([A-Za-z0-9_]+)");
		urls = new Regex("((http|https|ftp)://([\\S]+)\\.([\\S]+))");
		tags = new Regex("((^|\\s)\\#[A-Za-z0-9_äëḧïöüẅẍÿÄÖÜßéèáàÉÈÁÀ]+)");
		
		var scroll = new ScrolledWindow(null, null);
        scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add(entry);
		
		var hbox = new HBox(false, 1);
		hbox.pack_start(scroll, true, true, 0);
		
		var frame = new Frame(null);
		frame.set_size_request(-1, 60);
		frame.add(hbox);
		
		var sep = new HSeparator();
		
		pack_start(sep, false, false, 0);
		pack_start(l_box, false, false, 0);
		pack_start(frame, false, true, 0);
	}
	
	private void spellEnabling() {
		if(prefs.enableSpell) {
			if(prefs.enableSpell) {
				try {
					Spell spell = new Spell.attach(entry, null);
				} catch(Error e) {
					try {
						Spell spell = new Spell.attach(entry, "en_US");
					} catch(Error e) {
						warning(e.message);
					}
					warning(e.message);
				}
			}
		} else {
			Spell spell = Spell.get_from_text_view(entry);
			if(spell != null)
				spell.detach();
		}
	}
	
	public void update_auth() {
		var acc = accounts.get_current_account();
		
		api.set_auth(acc);
	}
	
	public void set_screen_name(string user_name) {
		user_label.set_text(_("Reply to <b>%s</b>:").printf(user_name));
		user_label.set_use_markup(true);
	}
	
	private void clear() {
		text = "";
	}
	
	public void insert(string str) {
		entry.buffer.insert_at_cursor(str, (int)str.length);
	}
	
	/* when user clicked on a nick */
	public void set_nickto(string screen_name) {
		if(!visible)
			set_state_new();
			
		insert("@%s ".printf(screen_name));
	}
	
	public void set_state_new() {
		state = State.NEW;
		
		direct_entry.hide();
		clear();
		show();
		status_icon.set_from_stock(STOCK_EDIT, IconSize.SMALL_TOOLBAR);
		user_label.set_text(_("New status:"));
		parent.set_focus(text_entry);
	}
	
	public void set_state_reply(Status status) {
		state = State.REPLY;
		reply_id = status.id;
		
		direct_entry.hide();
		clear();
		show();
		
		status_icon.set_from_file(Config.REPLY_PATH);
		user_label.set_text(_("Reply to") + " <b>%s</b>:".printf(status.user_screen_name));
		user_label.set_use_markup(true);
		text = "@%s ".printf(status.user_screen_name);
		parent.set_focus(text_entry);
	}
	
	public void set_state_directreply(string screen_name) {
		state = State.DIRECT_REPLY;
		
		direct_entry.show();
		direct_entry.set_text(screen_name);
		
		status_icon.set_from_file(Config.DIRECT_REPLY_PATH);
		user_label.set_text(_("Direct message to"));
		user_label.set_use_markup(true);
		
		clear();
		show();
		
		if(screen_name != "") { // if new DM, not a "reply"
			direct_entry.check();
			parent.set_focus(text_entry);
		} else parent.set_focus(direct_entry);
	}
	
	public void set_state_retweet(Status status) {
		state = State.RETWEET;
		
		direct_entry.hide();
		clear();
		show();
		
		status_icon.set_from_file(Config.RETWEET_PATH);
		user_label.set_text(_("Retweet:"));
		
		switch(prefs.retweetStyle) {
			case ReTweet.Style.UNI:
				text = "♺ @%s: %s".printf(status.user_screen_name, status.text);
				break;
			
			case ReTweet.Style.CLASSIC:
				text = "RT @%s: %s".printf(status.user_screen_name, status.text);
				break;
			
			case ReTweet.Style.VIA:
				var msg = status.text;
				var via = " (via @%s)".printf(status.user_screen_name);
				
				if(msg.length > (140 - via.length))
					msg = msg.substring(0, 140 - via.length);
				
				text = msg + via;
				break;
		}
		
		parent.set_focus(text_entry);
	}
	
	private bool too_long() {
		if(text.length > 140) {
			var message_dialog = new MessageDialog(parent,
				Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
				Gtk.MessageType.INFO, Gtk.ButtonsType.OK, (_("Your status is too long")));
		
			message_dialog.run();
			message_dialog.destroy();
			
			return true;
		}
		return false;
		
	}
	
	private bool hide_or_send(Gdk.EventKey event) {
		switch(event.hardware_keycode) {
			case 36: //return key
				if(event.state == 1) { //shift + enter
					entry.buffer.insert_at_cursor("\n", (int)"\n".length);
					return true;
				}
				if(text.length > 0) {
					enter_pressed();
				} else { // if nothing to send
					var message_dialog = new MessageDialog(parent,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.INFO, Gtk.ButtonsType.OK,
					(_("Type something first")));
					
					message_dialog.run();
					message_dialog.destroy();
				}
				return true;
		
		case 9: //esc key
			clear();
			hide();
			break;
		}
		
		return false;
	}
	
	private void enter_pressed() {
		switch(state) {
			case State.NEW:
				if(!too_long())
					send_new();
				break;
			
			case State.REPLY:
				if(!too_long())
					send_new(reply_id);
				break;
			
			case State.RETWEET:
				if(!too_long())
					send_new();
				break;
			
			case State.DIRECT_REPLY:
				send_dm();
				break;
		}
	}
	
	private void send_new(string reply_id = "") {
		set_sensitive(false);
		
		sending_data(_("Sending status...")); //signal
		
		Status status = null;
		try {
			status = api.update_status(text, reply_id);
		} catch(RestError e) {
			set_sensitive(true);
			
			data_error_sent(e.message);
			return;
		}
		
		status.tmp = true;
		status_updated(status); //signal
		
		hide();
		set_sensitive(true);
		
		data_sent(_("Your status has been sent successfully")); //signal
	}
	
	private void send_dm() {
		set_sensitive(false);
		
		sending_data(_("Sending direct message...")); //signal
		
		try {
			api.send_dm(direct_entry.text, text);
		} catch(RestError e) {
			set_sensitive(true);
			
			data_error_sent(e.message);
			return;
		}
		
		hide();
		set_sensitive(true);
		
		data_sent(_("Your direct message has been sent successfully")); //signal
	}
	
	/* styling for nicks in the buffer */
	private void tagging(TextIter start_pos, string text, Regex regex, string tag_name) {
		ArrayList<string> lst = new ArrayList<string>();
		int pos = 0;
		
		while(true) {
			MatchInfo match_info;
			bool bingo = regex.match_all_full(text, -1, pos, GLib.RegexMatchFlags.NEWLINE_ANY, out match_info);
			
			if(bingo) {
				foreach(string s in match_info.fetch_all()) {
					lst.add(s);
					
					match_info.fetch_pos(0, null, out pos);
					break;
				}
			} else break;
		}
		
		foreach(string item in lst) {
			TextIter start_pos_regex;
			TextIter end_pos_regex;
			
			start_pos.forward_search(item, TextSearchFlags.TEXT_ONLY,
				out start_pos_regex, out end_pos_regex, null);
			
			entry.buffer.apply_tag_by_name(tag_name, start_pos_regex, end_pos_regex);
		}
	}
	
	private void change() {
		int length = (int)text.len();
		
		TextIter start_pos;
		TextIter end_pos;
		
		entry.buffer.get_bounds(out start_pos, out end_pos);
		
		//entry.buffer.remove_all_tags(start_pos, end_pos);
		entry.buffer.remove_tag_by_name("red_bg", start_pos, end_pos);
		entry.buffer.remove_tag_by_name("url", start_pos, end_pos);
		entry.buffer.remove_tag_by_name("nick", start_pos, end_pos);
		entry.buffer.remove_tag_by_name("tag", start_pos, end_pos);
		
		tagging(start_pos, text, urls, "url");
		tagging(start_pos, text, nicks, "nick");
		tagging(start_pos, text, tags, "tag");
		
		if(length > 140) {
			TextIter start_red_pos;
			
			entry.buffer.get_iter_at_offset(out start_red_pos, 140);
			entry.buffer.get_iter_at_offset(out end_pos, length);
			
			entry.buffer.apply_tag_by_name("red_bg", start_red_pos, end_pos);
		}
		
		label.set_text("<b>%s</b>".printf((140 - text.len()).to_string()));
		label.set_use_markup(true);
	}
}
