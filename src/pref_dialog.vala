/* pref_dialog.vala
 *
 * Copyright (C) 2009  troorl
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

public class PrefDialog : Dialog {
	
	private Notebook tabs;
	private SpinButton updateInterval;
	private CheckButton showTimelineNotify;
	private CheckButton showMentionsNotify;
	private CheckButton showDirectNotify;
	
	private RadioButton showFullNotify;
	private RadioButton showLowNotify;
	
	private ComboBox retweetStyle;
	private Button deleteCache;
	private CheckButton roundedAvatars;
	private HScale opacityTweets;
	private CheckButton rtlSupport;
	private Entry login;
	private Entry password;
	private CheckButton savePass;
	
	public signal void delete_cache();
	
	public PrefDialog(Prefs prefs, Window parent) {
		this.modal = true;
		set_title(_("Preferences"));
		this.has_separator = false;
		
		tabs = new Notebook();
		
		//main page
		var main_box = new VBox(false, 10);
		
		//update interval
		var updateLabel = new Label(_("Update interval"));
		updateInterval = new SpinButton.with_range(1, 60, 1);
		
		//show notifications
		showTimelineNotify = new CheckButton.with_label(_("For timeline"));
		showMentionsNotify = new CheckButton.with_label(_("For mentions"));
		showDirectNotify = new CheckButton.with_label(_("For direct messages"));
		
		weak SList<weak Gtk.RadioButton> group_not  = null;
		showFullNotify = new RadioButton.with_label(group_not,
			_("Show notification for each status"));
		showLowNotify = new RadioButton.with_label(showFullNotify.get_group(),
			_("Show overall notification"));
		
		//retweet style
		var reLabel = new Label(_("Retweets style"));
		retweetStyle = new ComboBox.text();
		retweetStyle.append_text("RT @username: message");
		retweetStyle.append_text("♺ @username: message");
		retweetStyle.append_text("message (via @username)");
		
		//delete cache
		deleteCache = new Button.with_label(_("Clear now"));
		var del_img = new Image.from_icon_name("gtk-clear", IconSize.BUTTON);
		deleteCache.set_image(del_img);
		deleteCache.clicked.connect(() => {
			delete_cache();
		});
		
		var table_int = new HigTable(_("Time interval"));
		table_int.add_two_widgets(updateLabel, updateInterval);
		
		var table_not = new HigTable(_("Notification"));
		table_not.add_widget(showTimelineNotify);
		table_not.add_widget(showMentionsNotify);
		table_not.add_widget(showDirectNotify);
		table_not.add_two_widgets(showFullNotify, showLowNotify);
		
		var table_re = new HigTable(_("Retweets"));
		table_re.add_two_widgets(reLabel, retweetStyle);
		
		var table_cache = new HigTable(_("Cache"));
		table_cache.add_widget(deleteCache);
		
		main_box.pack_start(table_int, false, true, 10);
		main_box.pack_start(table_not, false, true, 10);
		main_box.pack_start(table_re, false, true, 10);
		main_box.pack_start(table_cache, false, true, 10);
		
		//account page
		var ac_box = new VBox(false, 0);
		
		//login
		var logLabel = new Label(_("Login"));
		login = new Entry();
		
		//password
		var pasLabel = new Label(_("Password"));
		password = new Entry();
		password.visible = 0;
		
		password.key_press_event.connect((event) => {
			if(event.hardware_keycode == 36) {
				close();
				return true;
			} else
				return false;
		});
		
		//save password
		savePass = new CheckButton.with_label(_("Remember password"));
		savePass.active = true;
		
		savePass.toggled.connect(() => {
			//
		});
		
		var table_auth = new HigTable(_("Authorization"));
		table_auth.add_two_widgets(logLabel, login);
		table_auth.add_two_widgets(pasLabel, password);
		table_auth.add_widget(savePass);
		
		ac_box.pack_start(table_auth, false, true, 10);
		
		if(prefs.is_new) {
			var start_box = new HBox(false, 0);
			var start_button = new Button.with_label(_("Create new account..."));
			
			start_button.clicked.connect(() => {
				GLib.Pid pid;
				GLib.Process.spawn_async(".", {"/usr/bin/xdg-open",
					"http://twitter.com/signup"}, null,
					GLib.SpawnFlags.STDOUT_TO_DEV_NULL, null, out pid);
			});
			
			start_box.pack_start(start_button, false, true, 10);
			ac_box.pack_start(start_box, false, true, 10);
		}
		
		//Appearance tab
		var app_box = new VBox(false, 0);
		
		var table_tweets = new HigTable(_("Tweets"));
		
		//rounded corners
		roundedAvatars = new CheckButton.with_label(_("Rounded corners"));
		
		//rtl support
		rtlSupport = new CheckButton.with_label(_("Right-to-left languages detection"));
		
		//opacity for tweets
		var opacityTweetsLabel = new Label(_("Opacity"));
		opacityTweets = new HScale.with_range(0, 100, 5);
		opacityTweets.set_size_request(150, -1);
		
		table_tweets.add_widget(roundedAvatars);
		table_tweets.add_widget(rtlSupport);
		table_tweets.add_two_widgets(opacityTweetsLabel, opacityTweets);
		
		app_box.pack_start(table_tweets, false, true, 10);
		
		tabs.append_page(main_box, new Label(_("Main")));
		tabs.append_page(ac_box, new Label(_("Account")));
		tabs.append_page(app_box, new Label(_("Appearance")));
		
		var hor_box = new HBox(false, 0);
		hor_box.pack_start(tabs, true, true, 10);
		
		this.vbox.pack_start(hor_box, true, true, 10);
		this.vbox.set_spacing(0);
		
		//action buttons
		add_button(STOCK_CLOSE, ResponseType.CLOSE);
		
		this.response.connect(response_acts);
		
		//setup preferences
		setup_prefs(prefs);
		
		//setup signals for prefs
		setup_prefs_signals(prefs);
		
		show_all();
		set_transient_for(parent);
		
		//if first start or don't want to remember the password
		if(prefs.is_new || !prefs.rememberPass) {	
			tabs.set_current_page(1);
		}
		
		if(!prefs.rememberPass)
			set_focus(password);
	}
	
	private void setup_retweet(Prefs prefs) {
		switch(prefs.retweetStyle) {
			case ReTweet.Style.CLASSIC:
				retweetStyle.set_active(0);
				break;
			
			case ReTweet.Style.UNI:
				retweetStyle.set_active(1);
				break;
			
			case ReTweet.Style.VIA:
				retweetStyle.set_active(2);
				break;
		}
	}
	
	private void setup_prefs(Prefs prefs) {
		updateInterval.value = prefs.updateInterval;
		showTimelineNotify.active = prefs.showTimelineNotify;
		showMentionsNotify.active = prefs.showMentionsNotify;
		
		if(prefs.showFullNotify)
			showFullNotify.active = true;
		else
			showLowNotify.active = true;
		
		showDirectNotify.active = prefs.showDirectNotify;
		setup_retweet(prefs);
		roundedAvatars.active = prefs.roundedAvatars;
		opacityTweets.set_value((int)(prefs.opacityTweets.to_double() * 100));
		rtlSupport.active = prefs.rtlSupport;
		login.text = prefs.login;
		password.text = prefs.password;
		savePass.active = prefs.rememberPass;
	}
	
	private void setup_prefs_signals(Prefs prefs) {
		updateInterval.value_changed.connect(() => {
			prefs.updateInterval = (int)updateInterval.value;
		});
		
		roundedAvatars.toggled.connect(() => {
			prefs.roundedAvatars = roundedAvatars.active;
		});
		
		opacityTweets.change_value.connect((scroll, new_value) => {
			if(new_value > 100)
				new_value = 100;
			
			string str_val = (new_value / 100).to_string();
		
			if(str_val != "1" && str_val != "0") {
				if(str_val.length < 4)
					str_val = str_val.substring(1, 2);
				else
					str_val = str_val.substring(1, 3);
			}
		
			prefs.opacityTweets = str_val;
			return false;
		});
		
		rtlSupport.toggled.connect(() => {
			prefs.rtlSupport = rtlSupport.active;
		});
		
		showTimelineNotify.toggled.connect(() => {
			prefs.showTimelineNotify = showTimelineNotify.active;
		});
		
		showMentionsNotify.toggled.connect(() => {
			prefs.showMentionsNotify = showMentionsNotify.active;
		});
		
		showDirectNotify.toggled.connect(() => {
			prefs.showDirectNotify = showDirectNotify.active;
		});
		
		showFullNotify.toggled.connect(() => {
			prefs.showFullNotify = showFullNotify.active;
		});
		
		retweetStyle.changed.connect(() => {
			switch(retweetStyle.get_active()) {
				case 0:
					prefs.retweetStyle = ReTweet.Style.CLASSIC;
					break;
				
				case 1:
					prefs.retweetStyle = ReTweet.Style.UNI;
					break;
				
				case 2:
					prefs.retweetStyle = ReTweet.Style.VIA;
					break;
			}
		});
		
		login.changed.connect(() => {
			prefs.login = login.text;
		});
		
		password.changed.connect(() => {
			prefs.password = password.text;
		});
		
		savePass.toggled.connect(() => {
			prefs.rememberPass = savePass.active;
		});
	}
	
	private void response_acts(int resp_id) {
		switch(resp_id) {
			case ResponseType.CLOSE:
				close();
				break;
		}
	}	
}
