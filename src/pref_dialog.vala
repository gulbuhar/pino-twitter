/* pref_dialog.vala
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

public class PrefDialog : Dialog {
	
	private Notebook tabs;
	
	private SpinButton updateInterval;
	private SpinButton numberStatuses;
	private ComboBox urlShorten;
	private CheckButton enableSpell;
	private CheckButton startMin;
	private CheckButton showTray;
	private CheckButton showTimelineNotify;
	private CheckButton showMentionsNotify;
	private CheckButton showDirectNotify;
	
	//private RadioButton showFullNotify;
	private RadioButton showLowNotify;
	
	private ComboBox retweetStyle;
	private Button deleteCache;
	private CheckButton roundedAvatars;
	private HScale opacityTweets;
	private CheckButton rtlSupport;
	private CheckButton fullNames;
	private CheckButton nativeLinkColor;
	private FontButton deFont;
	private ColorButton freshColor;
	private Entry login;
	private Entry password;
	private CheckButton savePass;
	
	public signal void delete_cache();
	
	public PrefDialog(Prefs prefs, Window parent, Accounts accounts) {
		this.modal = true;
		set_title(_("Preferences"));
		this.has_separator = false;
		
		tabs = new Notebook();
		
		//main page
		var main_box = new VBox(false, 10);
		
		//update interval
		var updateLabel = new Label(_("Update interval (in minutes)"));
		updateInterval = new SpinButton.with_range(1, 60, 1);
		
		//default number of statuses in lists
		var numberStatusesLabel = new Label(_("Default number of statuses"));
		numberStatuses = new SpinButton.with_range(5, 100, 1);
		
		//URL shortening service
		var urlShortenLabel = new Label(_("URL shortening service"));
		urlShorten = new ComboBox.text();
		urlShorten.append_text("goo.gl");
		urlShorten.append_text("is.gd");
		urlShorten.append_text("ur1.ca");
		
		//enabling spell checking
		enableSpell = new CheckButton.with_label(_("Enable spell checking"));
		
		//start in tray
		startMin = new CheckButton.with_label(_("Starting up in tray"));
		
		//show tray icon
		showTray = new CheckButton.with_label(_("Show tray icon"));
		
		//show notifications
		showTimelineNotify = new CheckButton.with_label(_("For timeline"));
		showMentionsNotify = new CheckButton.with_label(_("For mentions"));
		showDirectNotify = new CheckButton.with_label(_("For direct messages"));
		/*
		weak SList<weak Gtk.RadioButton> group_not  = null;
		showFullNotify = new RadioButton.with_label(group_not,
			_("Show notification for each status"));
		showLowNotify = new RadioButton.with_label(showFullNotify.get_group(),
			_("Show overall notification"));
		*/
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
		
		var table_int = new HigTable(_("General"));
		table_int.add_two_widgets(updateLabel, updateInterval);
		table_int.add_two_widgets(numberStatusesLabel, numberStatuses);
		table_int.add_two_widgets(urlShortenLabel, urlShorten);
		table_int.add_widget(enableSpell);
		
		var table_re = new HigTable(_("Retweets"));
		table_re.add_two_widgets(reLabel, retweetStyle);
		
		var table_cache = new HigTable(_("Cache"));
		table_cache.add_widget(deleteCache);
		
		main_box.pack_start(table_int, false, true, 10);
		main_box.pack_start(table_re, false, true, 10);
		main_box.pack_start(table_cache, false, true, 10);
		
		//desktop preferences
		var de_box = new VBox(false, 0);
		
		//tray
		var table_tr = new HigTable(_("Notification area"));
		table_tr.add_widget(startMin);
		table_tr.add_widget(showTray);
		
		var table_not = new HigTable(_("Notification"));
		table_not.add_widget(showTimelineNotify);
		table_not.add_widget(showMentionsNotify);
		table_not.add_widget(showDirectNotify);
		
		de_box.pack_start(table_tr, false, true, 10);
		de_box.pack_start(table_not, false, true, 10);
		
		//account page
		var ac_box = new VBox(false, 0);
		
		//accounts
		AccountWidget accountWidget = new AccountWidget(this, accounts);
		
		var table_auth = new HigTable(_("Authorization"));
		table_auth.add_widget_wide(accountWidget);
		
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
		
		var table_tweets = new HigTable(_("Statuses"));
		
		//rounded corners
		roundedAvatars = new CheckButton.with_label(_("Rounded corners"));
		
		//rtl support
		rtlSupport = new CheckButton.with_label(_("Right-to-left languages detection"));
		
		//full names or nicks in tweets
		fullNames = new CheckButton.with_label(_("Full names instead of nicknames"));
		
		//link color
		nativeLinkColor = new CheckButton.with_label(_("Native links color"));
		
		//default font in statuses
		var deFontLabel = new Label(_("Default font"));
		deFont = new FontButton();
		deFont.set_use_size(true);
		deFont.set_show_style(false);
		
		//color of fresh statuses
		var freshColorLabel = new Label(_("Fresh statuses color"));
		freshColor = new ColorButton();
		freshColor.set_use_alpha(true);
		
		//opacity for tweets
		var opacityTweetsLabel = new Label(_("Opacity"));
		opacityTweets = new HScale.with_range(0, 100, 5);
		opacityTweets.set_size_request(150, -1);
		
		table_tweets.add_widget(roundedAvatars);
		table_tweets.add_widget(rtlSupport);
		table_tweets.add_widget(fullNames);
		table_tweets.add_widget(nativeLinkColor);
		table_tweets.add_two_widgets(deFontLabel, deFont);
		table_tweets.add_two_widgets(freshColorLabel, freshColor);
		table_tweets.add_two_widgets(opacityTweetsLabel, opacityTweets);
		
		app_box.pack_start(table_tweets, false, true, 10);
		
		tabs.append_page(main_box, new Label(_("Main")));
		tabs.append_page(de_box, new Label(_("Desktop")));
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
		
		set_transient_for(parent);
		show_all();
		
		//if first start or don't want to remember the password
		if(accounts.is_new) {	
			tabs.set_current_page(2);
		}
	}
	
	private void setup_urlshorten(Prefs prefs) {
		switch(prefs.urlShorten) {
			case "goo.gl":
				urlShorten.set_active(0);
				break;
			
			case "is.gd":
				urlShorten.set_active(1);
				break;
			
			case "ur1.ca":
				urlShorten.set_active(2);
				break;
			
			default:
				urlShorten.set_active(0);
				break;
		}
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
		numberStatuses.value = prefs.numberStatuses;
		setup_urlshorten(prefs);
		enableSpell.active = prefs.enableSpell;
		startMin.active = prefs.startMin;
		showTray.active = prefs.showTray;
		showTimelineNotify.active = prefs.showTimelineNotify;
		showMentionsNotify.active = prefs.showMentionsNotify;
		/*
		if(prefs.showFullNotify)
			showFullNotify.active = true;
		else
			showLowNotify.active = true;
		*/
		showDirectNotify.active = prefs.showDirectNotify;
		setup_retweet(prefs);
		roundedAvatars.active = prefs.roundedAvatars;
		opacityTweets.set_value((int)(prefs.opacityTweets.to_double() * 100));
		rtlSupport.active = prefs.rtlSupport;
		fullNames.active = prefs.fullNames;
		nativeLinkColor.active = prefs.nativeLinkColor;
		deFont.set_font_name("%s %d".printf(prefs.deFontName, prefs.deFontSize));
		
		//colorFrsh setup
		uint16 alpha_fresh;
		var fresh_color = ColorUtils.rgba2color(prefs.freshColor, out alpha_fresh);
		//warning("%d", alpha_fresh);
		freshColor.set_color(fresh_color);
		freshColor.set_alpha(alpha_fresh);
	}
	
	private void setup_prefs_signals(Prefs prefs) {
		updateInterval.value_changed.connect(() => {
			prefs.updateInterval = (int)updateInterval.value;
		});
		
		numberStatuses.value_changed.connect(() => {
			prefs.numberStatuses = (int)numberStatuses.value;
		});
		
		urlShorten.changed.connect(() => {
			switch(urlShorten.get_active()) {
				case 0:
					prefs.urlShorten = "goo.gl";
					break;
				
				case 1:
					prefs.urlShorten = "is.gd";
					break;
				
				case 2:
					prefs.urlShorten = "ur1.ca";
					break;
			}
		});
		
		enableSpell.toggled.connect(() => {
			prefs.enableSpell = enableSpell.active;
		});
		
		startMin.toggled.connect(() => {
			prefs.startMin = startMin.active;
			
			if(prefs.startMin) //enabling tray
				showTray.active = true;
		});
		
		showTray.toggled.connect(() => {
			prefs.showTray = showTray.active;
			
			if(!prefs.showTray) //disable starting in tray
				startMin.active = false;
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
		
		fullNames.toggled.connect(() => {
			prefs.fullNames = fullNames.active;
		});
		
		nativeLinkColor.toggled.connect(() => {
			prefs.nativeLinkColor = nativeLinkColor.active;
		});
		
		deFont.font_set.connect(() => {
			//warning(deFont.get_font_name());
			prefs.deFont = deFont.get_font_name();
			//warning("font: %s, size: %d", prefs.deFontName, prefs.deFontSize);
		});
		
		freshColor.color_set.connect(() => {
			Gdk.Color fresh_color;
			freshColor.get_color(out fresh_color);
			double alpha = (double)freshColor.get_alpha() / 256.0 / 256.0;

			string result = ColorUtils.color2rgba(fresh_color, alpha);
			
			prefs.freshColor = result;
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
		/*
		showFullNotify.toggled.connect(() => {
			prefs.showFullNotify = showFullNotify.active;
		});
		*/
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
	}
	
	private void response_acts(int resp_id) {
		switch(resp_id) {
			case ResponseType.CLOSE:
				close();
				break;
		}
	}	
}
