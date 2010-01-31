/* main_window.vala
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
using WebKit;
using RestAPI;

public class MainWindow : Window {
	
	unowned SList<RadioAction> list_group;
	
	private Action updateAct;
	private ToggleAction menuAct;
	private ToggleAction toolbarAct;
	private TrayIcon tray;
	
	private Gdk.Pixbuf logo;
	private Gdk.Pixbuf logo_fresh;
	
	private Widget menubar;
	private Widget toolbar;
	private Menu popup;
	//private IconEntry searchEntry;
	private HBox sbox;
	
	private SystemStyle gtk_style;
	
	private TimelineList home;
	private TimelineList mentions;
	private TimelineDirectList direct;
	private ReTweet re_tweet;
	private StatusbarSmart statusbar;
	
	//private TwitterInterface twee;
	private Cache cache;
	private Template template;
	
	private Prefs prefs;
	private SmartTimer timer;
	
	private AuthData auth_data;
	
	private Popups notify;
	
	private bool focused;
	
	public MainWindow() {
		logo = new Gdk.Pixbuf.from_file(Config.LOGO_PATH);
		logo_fresh = new Gdk.Pixbuf.from_file(Config.LOGO_FRESH_PATH);
		
		//getting settings
		prefs = new Prefs();
		
		auth_data = { prefs.login, prefs.password };
		
		set_default_size (prefs.width, prefs.height);
		set_size_request(350, 300);
		
		//set window position
		if(prefs.left >= 0 && prefs.top >= 0)
			move(prefs.left, prefs.top);
		
		configure_event.connect((widget, event) => {
			//saving window size and position
			prefs.width = event.width;
			prefs.height = event.height;
			prefs.left = event.x;
			prefs.top = event.y;
			
			return false;
		});
		
		set_icon(logo);
		set_title(Config.APPNAME);
		
		//hiding on closing main window
		delete_event.connect((event) => {
			this.hide_on_delete();
			visible = false;
			focused = false;
			return true;
		});
		
		destroy.connect(() => before_close());
		
		gtk_style = new SystemStyle(rc_get_style(this));
		this.map_event.connect((event) => {
			gtk_style = new SystemStyle(rc_get_style(this));
			return true;
		});
		
		cache = new Cache();
		//template setup
		template = new Template(prefs, gtk_style, cache);
		
		//home timeline
		home = new TimelineList(this, auth_data, TimelineType.HOME,
			new TwitterUrls(), template, prefs.numberStatuses,
			Icon.new_for_string(Config.TIMELINE_PATH),
			Icon.new_for_string(Config.TIMELINE_FRESH_PATH), "HomeAct", _("Home timeline"),
			_("Show your home timeline"), true);
		
		//mentions
		mentions = new TimelineList(this, auth_data, TimelineType.MENTIONS,
			new TwitterUrls(), template, prefs.numberStatuses,
			Icon.new_for_string(Config.MENTIONS_PATH),
			Icon.new_for_string(Config.MENTIONS_FRESH_PATH), "MentionsAct", _("Mentions"),
			_("Show mentions"));
		
		//mentions
		direct = new TimelineDirectList(this, auth_data, new TwitterUrls(),
			template, prefs.numberStatuses,
			Icon.new_for_string(Config.DIRECT_PATH),
			Icon.new_for_string(Config.DIRECT_FRESH_PATH), "DirectAct", _("Direct messages"),
			_("Show direct messages"));
		
		home.fresh.connect(() => tray.new_tweets(true));
		mentions.fresh.connect(() => tray.new_tweets(true));
		direct.fresh.connect(() => tray.new_tweets(true));
		home.no_fresh.connect(() => check_fresh());
		mentions.no_fresh.connect(() => check_fresh());
		direct.no_fresh.connect(() => check_fresh());
		
		//group for lists
		list_group = home.act.get_group();
		mentions.act.set_group(home.act.get_group());
		direct.act.set_group(home.act.get_group());
		
		menu_init();
		
		//set popup menu to the views
		home.popup = popup;
		mentions.popup = popup;
		direct.popup = popup;
		
		//tray setup
		tray = new TrayIcon(this, logo, logo_fresh);
		tray.popup = popup;
		
		//retweet widget
		re_tweet = new ReTweet(this, prefs, cache);
		re_tweet.status_updated.connect((status) => {
			home.insert_status(status);
		});
		
		home.retweet.connect((status) => {
			re_tweet.set_state_retweet(status);
		});
		mentions.retweet.connect((status) => {
			re_tweet.set_state_retweet(status);
		});
		home.directreply.connect((screen_name) => {
			re_tweet.set_state_directreply(screen_name);
		});
		mentions.directreply.connect((screen_name) => {
			re_tweet.set_state_directreply(screen_name);
		});
		direct.directreply.connect((screen_name) => {
			re_tweet.set_state_directreply(screen_name);
		});
		home.replyto.connect((status) => {
			re_tweet.set_state_reply(status);
		});
		mentions.replyto.connect((status) => {
			re_tweet.set_state_reply(status);
		});
		
		//setup logging
		statusbar = new StatusbarSmart();
		home.start_update.connect((req) => statusbar.logging(req));
		mentions.start_update.connect((req) => statusbar.logging(req));
		direct.start_update.connect((req) => statusbar.logging(req));
		home.finish_update.connect(() => statusbar.logging(_("updated ")));
		mentions.finish_update.connect(() => statusbar.logging(_("updated ")));
		direct.finish_update.connect(() => statusbar.logging(_("updated ")));
		home.updating_error.connect((msg) => statusbar.log_warning(msg));
		mentions.updating_error.connect((msg) => statusbar.log_warning(msg));
		direct.updating_error.connect((msg) => statusbar.log_warning(msg));
		
		VBox vbox = new VBox(false, 0);
		vbox.pack_start(menubar, false, false, 0);
		vbox.pack_start(toolbar, false, false, 0);
		//vbox.pack_start(sbox, false, false, 0);
		vbox.pack_start(home, true, true, 0);
		vbox.pack_start(mentions, true, true, 0);
		vbox.pack_start(direct, true, true, 0);
		vbox.pack_end(statusbar, false, false, 0);
		vbox.pack_end(re_tweet, false, false, 0);
		
		this.add(vbox);
		
		//show window
		show_all();
		
		if(prefs.is_new || !prefs.rememberPass)
			run_prefs();
		
		//notification popups
		notify = new Popups(prefs, cache, logo);
		
		//searchEntry.hide();
		re_tweet.hide();
		mentions.hide();
		direct.hide();
		
		//hide menubar and toolbar if needed
		if(!prefs.menuShow)
			menuAct.set_active(false);
		if(!prefs.toolbarShow)
			toolbarAct.set_active(false);
		
		//getting updates
		if(!prefs.is_new && prefs.rememberPass) {
			refresh_action();
		}
	}
	
	private void menu_init() {	
		var actGroup = new ActionGroup("main");
		
		//file menu
		var fileMenu = new Action("FileMenu", _("Twitter"), null, null);
		
		var createAct = new Action("FileCreate", _("New status"),
			_("Create new status"), STOCK_EDIT);
		createAct.activate.connect(() => { re_tweet.set_state_new(); });
		
		var createDirectAct = new Action("FileCreateDirect", _("New direct message"),
			_("Create new direct message"), null);
		createDirectAct.set_gicon(Icon.new_for_string(Config.DIRECT_REPLY_PATH));
		createDirectAct.activate.connect(() => {
			re_tweet.set_state_directreply("");
		});
		
		updateAct = new Action("FileUpdate", _("Update timeline"),
			null, STOCK_REFRESH);
		updateAct.activate.connect(refresh_action);
		var quitAct = new Action("FileQuit", _("Quit"),
			null, STOCK_QUIT);
		quitAct.activate.connect(before_close);
		
		//edit menu
		var editMenu = new Action("EditMenu", _("Edit"), null, null);
		var prefAct = new Action("EditPref", _("Preferences"),
			null, STOCK_PREFERENCES);
		prefAct.activate.connect(run_prefs);
		
		//view menu
		var viewMenu = new Action("ViewMenu", _("View"), null, null);
		/*
		var showTimelineAct = new RadioAction("ShowTimelineAct", _("Timeline"),
			_("Show your timeline"), null, 1);
		showTimelineAct.set_gicon(Icon.new_for_string(Config.TIMELINE_PATH));
		showTimelineAct.active = true;
		
		showTimelineAct.changed.connect((current) => {
			if(current == showTimelineAct) {
				mentions.hide();
				home.show();
			}
		});
		
		var showMentionsAct = new RadioAction("ShowMentionsAct", _("Mentions"),
			_("Show mentions"), null, 1);
		showMentionsAct.set_gicon(Icon.new_for_string(Config.MENTIONS_PATH));
		
		showMentionsAct.changed.connect((current) => {
			if(current == showMentionsAct) {
				home.hide();
				mentions.show();
			}
		});
		*/
		//showMentionsAct.set_group(showTimelineAct.get_group()); //lol
		
		menuAct = new ToggleAction("ViewMenuAct", _("Show menu"), null, null);
		menuAct.set_active(true);
		
		menuAct.toggled.connect(() => {
			if(menuAct.active)
				menubar.show();
			else
				menubar.hide();
		});
		
		toolbarAct = new ToggleAction("ViewToolbar", _("Show toolbar"),
			null, null);
		toolbarAct.set_active(true);
		
		toolbarAct.toggled.connect(() => {
			if(toolbarAct.active)
				toolbar.show();
			else
				toolbar.hide();
		});
		
		//help menu
		var helpMenu = new Action("HelpMenu", _("Help"), null, null);
		var aboutAct = new Action("HelpAbout", _("About %s").printf(Config.APPNAME),
			null, STOCK_ABOUT);
		
		aboutAct.activate.connect(() => {
			var about_dlg = new AboutDialog();
			about_dlg.set_logo(logo);
			about_dlg.set_program_name(Config.APPNAME);
			about_dlg.set_version(Config.APP_VERSION);
			about_dlg.set_website("http://pino-app.appspot.com/");
			about_dlg.set_authors({Config.AUTHORS});
			about_dlg.set_copyright("© 2009 troorl");
			
			about_dlg.set_transient_for(this);
			about_dlg.run();
			about_dlg.hide();
		});
		
		actGroup.add_action(fileMenu);
		actGroup.add_action_with_accel(createAct, "<Ctrl>N");
		actGroup.add_action_with_accel(createDirectAct, "<Ctrl>D");
		actGroup.add_action_with_accel(updateAct, "<Ctrl>R");
		actGroup.add_action_with_accel(quitAct, "<Ctrl>Q");
		actGroup.add_action(editMenu);
		actGroup.add_action_with_accel(prefAct, "<Ctrl>P");
		actGroup.add_action(viewMenu);
		actGroup.add_action_with_accel(home.act, "<Ctrl>1");
		actGroup.add_action_with_accel(mentions.act, "<Ctrl>2");
		actGroup.add_action_with_accel(direct.act, "<Ctrl>3");
		//actGroup.add_action(showTimelineAct);
		//actGroup.add_action(showMentionsAct);
		actGroup.add_action_with_accel(menuAct, "<Ctrl>M");
		actGroup.add_action(toolbarAct);
		actGroup.add_action(helpMenu);
		actGroup.add_action(aboutAct);
		
		var ui = new UIManager();
		ui.insert_action_group(actGroup, 0);
		this.add_accel_group(ui.get_accel_group());
		
		var uiString = """
		<ui>
			<menubar name="MenuBar">
				<menu action="FileMenu">
					<menuitem action="FileCreate" />
					<menuitem action="FileCreateDirect" />
					<menuitem action="FileUpdate" />
					<separator />
					<menuitem action="FileQuit" />
				</menu>
				<menu action="EditMenu">
					<menuitem action="EditPref" />
				</menu>
				<menu action="ViewMenu">
					<menuitem action="HomeAct" />
					<menuitem action="MentionsAct" />
					<menuitem action="DirectAct" />
					<separator />
					<menuitem action="ViewMenuAct" />
					<menuitem action="ViewToolbar" />
				</menu>
				<menu action="HelpMenu">
					<menuitem action="HelpAbout" />
				</menu>
			</menubar>
			<popup name="MenuPopup">
				<menuitem action="FileCreate" />
				<menuitem action="FileCreateDirect" />
				<menuitem action="FileUpdate" />
				<separator />
				<menuitem action="EditPref" />
				<separator />
				<menuitem action="ViewMenuAct" />
				<menuitem action="ViewToolbar" />
				<separator />
				<menuitem action="HelpAbout" />
				<menuitem action="FileQuit" />
			</popup>
			<toolbar name="ToolBar">
				<toolitem action="FileCreate" />
				<toolitem action="FileUpdate" />
				<separator />
				<toolitem action="EditPref" />
				<separator />
				<toolitem action="HomeAct" />
				<toolitem action="MentionsAct" />
				<toolitem action="DirectAct" />
			</toolbar>
		</ui>
		""";
		
		ui.add_ui_from_string(uiString, uiString.length);
		
		menubar = ui.get_widget("/MenuBar");
		popup = (Menu)ui.get_widget("/MenuPopup");
		toolbar = ui.get_widget("/ToolBar");
	}
	
	/*
	private void show_re_tweet() {
		reTweet.clear();
		reTweet.is_direct = false;
		reTweet.show();
		this.set_focus(reTweet.text_entry);
	}
	*/
	
	public void refresh_action() {
		updateAct.set_sensitive(false);
		
		statusbar.set_status(StatusbarSmart.StatusType.UPDATING);
		
		var home_list = home.update();
		var mentions_list = mentions.update();
		var direct_list = direct.update();
		
		statusbar.set_status(StatusbarSmart.StatusType.FINISH_OK);
		
		notify.start(home_list, mentions_list, direct_list);
		
		/*
		Gee.ArrayList<string> exclude = new Gee.ArrayList<string>();
		
		switch(twee.sync_friends(last_time_friends, last_focused_friends)) {
			case TwitterInterface.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case TwitterInterface.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case TwitterInterface.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case TwitterInterface.Reply.OK:
				tweets.load_string(template.generate_timeline(twee.friends, gtkStyle, prefs, last_focused_friends),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_friends > 0 &&
					last_time_friends < (int)twee.friends.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showTimelineNotify && last_time_friends > 0)
					exclude = show_popups(twee.friends, last_time_friends, exclude);
				
				last_time_friends = (int)twee.friends.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_friends = last_time_friends;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				tweets.load_string(template.generate_timeline(twee.friends, gtkStyle, prefs, last_focused_friends),
					"text/html", "utf8", "file:///");
				break;
		}
		
		switch(twee.sync_mentions(last_time_mentions, last_focused_mentions)) {
			case TwitterInterface.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case TwitterInterface.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case TwitterInterface.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case TwitterInterface.Reply.OK:
				mentions.load_string(template.generate_timeline(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_mentions > 0 &&
					last_time_mentions < (int)twee.mentions.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showMentionsNotify && last_time_mentions > 0)
					show_popups(twee.mentions, last_time_mentions, exclude);
				
				last_time_mentions = (int)twee.mentions.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_mentions = last_time_mentions;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				mentions.load_string(template.generate_timeline(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				break;
		}
		*/
		updateAct.set_sensitive(true);
	}
	
	private void run_prefs() {
		var pref_dialog = new PrefDialog(prefs, this);
		
		pref_dialog.delete_cache.connect(() => {
			cache.delete_cache();
		});
		
		pref_dialog.destroy.connect(() => {
			//timer interval update
			timer.set_interval(prefs.updateInterval * 60);
			
			var old_login = auth_data.login;
			
			auth_data = { prefs.login, prefs.password };
			
			prefs.write();
			
			if(prefs.is_new || old_login != prefs.login) { //if new settings or changing login
				updateAct.set_sensitive(false);
				statusbar.set_status(StatusbarSmart.StatusType.UPDATING);
				
				re_tweet.set_auth(auth_data);
				home.set_auth(auth_data);
				mentions.set_auth(auth_data);
				direct.set_auth(auth_data);
				
				home.items_count = prefs.numberStatuses;
				mentions.items_count = prefs.numberStatuses;
				direct.items_count = prefs.numberStatuses;
				
				statusbar.set_status(StatusbarSmart.StatusType.FINISH_OK);
				updateAct.set_sensitive(true);
			}
			
			prefs.is_new = false;
		});
		
		pref_dialog.set_transient_for(this);
		pref_dialog.show();
	}
	
	/* saving settings */
	private void before_close() {
		prefs.menuShow = menubar.visible;
		prefs.toolbarShow = toolbar.visible;
		
		prefs.write();
		main_quit();
	}
	
	private void check_fresh() {
		if(!(home.have_fresh || mentions.have_fresh || direct.have_fresh))
			tray.new_tweets(false);
	}
	
	/*
	public MainWindow() {
		logo = new Gdk.Pixbuf.from_file(Config.LOGO_PATH);
		logo_fresh = new Gdk.Pixbuf.from_file(Config.LOGO_FRESH_PATH);
		
		//getting settings
		prefs = new Prefs();
		prefs.roundedAvatarsChanged.connect(() => style_update(style));
		prefs.opacityTweetsChanged.connect(() => style_update(style));
		
		set_default_size (prefs.width, prefs.height);
		set_size_request(350, 300);
		
		//set window position
		if(prefs.left >= 0 && prefs.top >= 0)
			move(prefs.left, prefs.top);
		
		set_icon(logo);
		set_title(Config.APPNAME);
		
		//hiding on closing main window
		delete_event.connect((event) => {
			this.hide_on_delete();
			visible = false;
			focused = false;
			return true;
		});
		
		destroy.connect(() => before_close());
		
		configure_event.connect((widget, event) => {
			//saving window size and position
			prefs.width = event.width;
			prefs.height = event.height;
			prefs.left = event.x;
			prefs.top = event.y;
			
			return false;
		});
		
		focus_in_event.connect((w, e) => {
			focused = true;
			//warning("focused");
			if(last_time_friends > 0)
				last_focused_friends = last_time_friends;
			
			if(last_time_mentions > 0)
				last_focused_mentions = last_time_mentions;
			
			//clear tray notification
			tray.set_from_file(Config.LOGO_PATH);
		});
		
		focus_out_event.connect((w, e) => {
			focused = false;
			//warning("unfocused");
			if(last_time_friends > 0)
				last_focused_friends = last_time_friends;
			
			if(last_time_mentions > 0)
				last_focused_mentions = last_time_mentions;
		});
		
		this.map_event.connect((event) => {
			gtkStyle = new SystemStyle(rc_get_style(this));
			return true;
		});
		this.style_set.connect(style_update);
		
		menu_init();
		
		//tray setup
		tray = new TrayIcon(logo, logo_fresh);
		tray.popup = popup;
		tray.activate.connect(() => {
			if(visible)
				this.hide();
			else
				this.show();
		});
		
		//template setup
		template = new Template();
		
		//timeline
		tweets = new WebView();
		tweets.set_maintains_back_forward_list(false);
		tweets.can_go_back_or_forward(0);
		tweets.navigation_policy_decision_requested.connect(link_clicking);
		tweets.button_press_event.connect(show_popup_menu);
		scroll_tweets = new ScrolledWindow(null, null);
        scroll_tweets.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll_tweets.add(tweets);
		
		//mentions
		mentions = new WebView();
		mentions.set_maintains_back_forward_list(false);
		mentions.can_go_back_or_forward(0);
		mentions.navigation_policy_decision_requested.connect(link_clicking);
		mentions.button_press_event.connect(show_popup_menu);
		scroll_mentions = new ScrolledWindow(null, null);
        scroll_mentions.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll_mentions.add(mentions);
		
		reTweet = new ReTweet();
		reTweet.enter_pressed.connect(send_status);
		reTweet.empty_pressed.connect(() => {
			var message_dialog = new MessageDialog(this,
				Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
				Gtk.MessageType.INFO, Gtk.ButtonsType.OK,
				(_("Type something first")));
			
			message_dialog.run();
			message_dialog.destroy();
		});
		
		statusbar = new StatusbarSmart();
		
		
		
		VBox vbox = new VBox(false, 0);
		vbox.pack_start(menubar, false, false, 0);
		vbox.pack_start(toolbar, false, false, 0);
		//vbox.pack_start(sbox, false, false, 0);
		vbox.pack_start(scroll_tweets, true, true, 0);
		vbox.pack_start(scroll_mentions, true, true, 0);
		vbox.pack_end(statusbar, false, false, 0);
		vbox.pack_end(reTweet, false, false, 0);
		
		this.add(vbox);
		
		//twetter interface setup
		twee = new TwitterInterface.with_auth(prefs.login, prefs.password);
		twee.updating.connect(() => {statusbar.set_status(statusbar.Status.UPDATING);});
		twee.send_status.connect(() => {statusbar.set_status(statusbar.Status.SEND_STATUS);});
		twee.updated.connect(() => {statusbar.set_status(statusbar.Status.UPDATED);});
		
		if(prefs.is_new || !prefs.rememberPass)
			run_prefs();
		
		get_my_userpic();
		
		//show window
		show_all();
		
		//searchEntry.hide();
		reTweet.hide();
		scroll_mentions.hide();
		
		//libnotify init
		Notify.init(Config.APPNAME);
		
		//hide menubar and toolbar if needed
		if(!prefs.menuShow)
			menuAct.set_active(false);
		if(!prefs.toolbarShow)
			toolbarAct.set_active(false);
		
		//getting updates
		if(!prefs.is_new && prefs.rememberPass) {
			tweets.hide();
			refresh_action();
			tweets.show();
		}
		
		//start timer
		timer = new SmartTimer(prefs.updateInterval * 60);
		timer.timeout.connect(refresh_action);
	}
	
	private void menu_init() {	
		var actGroup = new ActionGroup("main");
		
		//file menu
		var fileMenu = new Action("FileMenu", _("Twitter"), null, null);
		var createAct = new Action("FileCreate", _("New status"),
			_("Create new status"), STOCK_EDIT);
		createAct.activate.connect(show_re_tweet);
		updateAct = new Action("FileUpdate", _("Update timeline"),
			null, STOCK_REFRESH);
		updateAct.activate.connect(refresh_action);
		var quitAct = new Action("FileQuit", _("Quit"),
			null, STOCK_QUIT);
		quitAct.activate.connect(before_close);
		
		//edit menu
		var editMenu = new Action("EditMenu", _("Edit"), null, null);
		var prefAct = new Action("EditPref", _("Preferences"),
			null, STOCK_PREFERENCES);
		prefAct.activate.connect(run_prefs);
		
		//view menu
		var viewMenu = new Action("ViewMenu", _("View"), null, null);
		var showTimelineAct = new RadioAction("ShowTimelineAct", _("Timeline"),
			_("Show your timeline"), null, 1);
		showTimelineAct.set_gicon(Icon.new_for_string(Config.TIMELINE_PATH));
		showTimelineAct.active = true;
		
		showTimelineAct.changed.connect((current) => {
			if(current == showTimelineAct) {
				scroll_mentions.hide();
				scroll_tweets.show();
			}
		});
		
		var showMentionsAct = new RadioAction("ShowMentionsAct", _("Mentions"),
			_("Show mentions"), null, 2);
		showMentionsAct.set_gicon(Icon.new_for_string(Config.MENTIONS_PATH));
		
		showMentionsAct.changed.connect((current) => {
			if(current == showMentionsAct) {
				scroll_tweets.hide();
				scroll_mentions.show();
			}
		});
		
		showMentionsAct.set_group(showTimelineAct.get_group()); //lol
		
		menuAct = new ToggleAction("ViewMenuAct", _("Show menu"), null, null);
		menuAct.set_active(true);
		
		menuAct.toggled.connect(() => {
			if(menuAct.active)
				menubar.show();
			else
				menubar.hide();
		});
		
		toolbarAct = new ToggleAction("ViewToolbar", _("Show toolbar"),
			null, null);
		toolbarAct.set_active(true);
		
		toolbarAct.toggled.connect(() => {
			if(toolbarAct.active)
				toolbar.show();
			else
				toolbar.hide();
		});
		
		//help menu
		var helpMenu = new Action("HelpMenu", _("Help"), null, null);
		var aboutAct = new Action("HelpAbout", _("About %s").printf(Config.APPNAME),
			null, STOCK_ABOUT);
		
		aboutAct.activate.connect(() => {
			var about_dlg = new AboutDialog();
			about_dlg.set_logo(logo);
			about_dlg.set_program_name(Config.APPNAME);
			about_dlg.set_version(Config.APP_VERSION);
			about_dlg.set_website("http://pino-app.appspot.com/");
			about_dlg.set_authors({Config.AUTHORS});
			about_dlg.set_copyright("© 2009 troorl");
			
			about_dlg.set_transient_for(this);
			about_dlg.run();
			about_dlg.hide();
		});
		
		actGroup.add_action(fileMenu);
		actGroup.add_action_with_accel(createAct, "<Ctrl>N");
		actGroup.add_action_with_accel(updateAct, "<Ctrl>R");
		actGroup.add_action_with_accel(quitAct, "<Ctrl>Q");
		actGroup.add_action(editMenu);
		actGroup.add_action_with_accel(prefAct, "<Ctrl>P");
		actGroup.add_action(viewMenu);
		actGroup.add_action(showTimelineAct);
		actGroup.add_action(showMentionsAct);
		actGroup.add_action_with_accel(menuAct, "<Ctrl>M");
		actGroup.add_action(toolbarAct);
		actGroup.add_action(helpMenu);
		actGroup.add_action(aboutAct);
		
		var ui = new UIManager();
		ui.insert_action_group(actGroup, 0);
		this.add_accel_group(ui.get_accel_group());
		
		var uiString = """
		<ui>
			<menubar name="MenuBar">
				<menu action="FileMenu">
					<menuitem action="FileCreate" />
					<menuitem action="FileUpdate" />
					<separator />
					<menuitem action="FileQuit" />
				</menu>
				<menu action="EditMenu">
					<menuitem action="EditPref" />
				</menu>
				<menu action="ViewMenu">
					<menuitem action="ShowTimelineAct" />
					<menuitem action="ShowMentionsAct" />
					<separator />
					<menuitem action="ViewMenuAct" />
					<menuitem action="ViewToolbar" />
				</menu>
				<menu action="HelpMenu">
					<menuitem action="HelpAbout" />
				</menu>
			</menubar>
			<popup name="MenuPopup">
				<menuitem action="FileCreate" />
				<menuitem action="FileUpdate" />
				<separator />
				<menuitem action="EditPref" />
				<separator />
				<menuitem action="ViewMenuAct" />
				<menuitem action="ViewToolbar" />
				<separator />
				<menuitem action="HelpAbout" />
				<menuitem action="FileQuit" />
			</popup>
			<toolbar name="ToolBar">
				<toolitem action="FileCreate" />
				<toolitem action="FileUpdate" />
				<separator />
				<toolitem action="EditPref" />
				<separator />
				<toolitem action="ShowTimelineAct" />
				<toolitem action="ShowMentionsAct" />
			</toolbar>
		</ui>
		""";
		
		ui.add_ui_from_string(uiString, uiString.length);
		
		menubar = ui.get_widget("/MenuBar");
		popup = (Menu)ui.get_widget("/MenuPopup");
		toolbar = ui.get_widget("/ToolBar");
	}
	
	private void run_prefs() {
		var pref_dialog = new PrefDialog(prefs, this);
		
		pref_dialog.delete_cache.connect(() => {
			template.cache.delete_cache();
		});
		
		pref_dialog.destroy.connect(() => {
			//timer interval update
			timer.set_interval(prefs.updateInterval * 60);
			
			var old_login = twee.login_public;
			
			//auth data update
			twee.set_auth(prefs.login, prefs.password);
			
			prefs.write();
			
			if(prefs.is_new || old_login != prefs.login) { //if new settings or changing login
				twee.friends.clear();
				twee.mentions.clear();
				
				last_time_friends = 0;
				last_focused_friends = -1;
				last_time_mentions = 0;
				last_focused_mentions = -1;
				
				//refreshing userpic
				prefs.userpicUrl = "";
				get_my_userpic();
				
				refresh_action();
			}
			
			prefs.is_new = false;
		});
		
		pref_dialog.set_transient_for(this);
		pref_dialog.show();
	}
	
	private void style_update(Style? prevStyle) {
		gtkStyle.updateStyle(rc_get_style(this));
		tweets.load_string(template.generate_timeline(twee.friends, gtkStyle, prefs, last_focused_friends),
			"text/html", "utf8", "file:///");
		mentions.load_string(template.generate_timeline(twee.mentions, gtkStyle, prefs, last_focused_mentions),
			"text/html", "utf8", "file:///");
	}
	
	private bool link_clicking(WebFrame p0, NetworkRequest request,
		WebNavigationAction action, WebPolicyDecision decision) {
		if(request.uri == "")
			return false;
		
		var p = request.uri.split("://");
		var prot = p[0];
		var params = p[1];
		
		if(prot == "http" || prot == "https" || prot == "ftp") {
			GLib.Pid pid;
			GLib.Process.spawn_async(".", {"/usr/bin/xdg-open", request.uri}, null,
				GLib.SpawnFlags.STDOUT_TO_DEV_NULL, null, out pid);
			return true;
		}
		
		switch(prot) {
			case "nickto":
				reTweet.show();
				reTweet.insert("@" + params);
				this.set_focus(reTweet.text_entry);
				return true;
			
			case "directreply":
				var screen_name = params;
				reTweet.is_direct = true;
				reTweet.set_screen_name(screen_name.split("==")[1]);
				reTweet.reply_id = screen_name.split("==")[0];
				reTweet.show();
				reTweet.insert("@%s ".printf(screen_name.split("==")[1]));
				this.set_focus(reTweet.text_entry);
				return true;
			
			case "retweet":
				var status_id = params;
				var tweet = twee.get_status(status_id);
				
				
					reTweet.clear();
					reTweet.show();
					reTweet.set_retweet(tweet, prefs.retweetStyle);
					this.set_focus(reTweet.text_entry);
				
				
				return true;
			
			case "delete":
				var message_dialog = new MessageDialog(this,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
					(_("Sure you want to delete this tweet?")));
				
				var response = message_dialog.run();
				if(response == ResponseType.YES) {
					message_dialog.destroy();
					var status_id = params;
					warning(status_id);
					var reply = twee.destroyStatus(status_id);
					status_actions(reply);
				}
				message_dialog.destroy();
				return true;
			
			case "file":
				return false;
			
			default:
				return true;
		}
	}
	
	private void status_actions(TwitterInterface.Reply reply)
	{
		switch(reply) {
			case TwitterInterface.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case TwitterInterface.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case TwitterInterface.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case TwitterInterface.Reply.OK:
				refresh_action();
				break;
		}
	}
	
	private void show_re_tweet() {
		reTweet.clear();
		reTweet.is_direct = false;
		reTweet.show();
		this.set_focus(reTweet.text_entry);
	}
	
	public void refresh_action() {
		updateAct.set_sensitive(false);
		
		Gee.ArrayList<string> exclude = new Gee.ArrayList<string>();
		
		switch(twee.sync_friends(last_time_friends, last_focused_friends)) {
			case TwitterInterface.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case TwitterInterface.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case TwitterInterface.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case TwitterInterface.Reply.OK:
				tweets.load_string(template.generate_timeline(twee.friends, gtkStyle, prefs, last_focused_friends),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_friends > 0 &&
					last_time_friends < (int)twee.friends.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showTimelineNotify && last_time_friends > 0)
					exclude = show_popups(twee.friends, last_time_friends, exclude);
				
				last_time_friends = (int)twee.friends.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_friends = last_time_friends;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				tweets.load_string(template.generate_timeline(twee.friends, gtkStyle, prefs, last_focused_friends),
					"text/html", "utf8", "file:///");
				break;
		}
		
		switch(twee.sync_mentions(last_time_mentions, last_focused_mentions)) {
			case TwitterInterface.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case TwitterInterface.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case TwitterInterface.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case TwitterInterface.Reply.OK:
				mentions.load_string(template.generate_timeline(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_mentions > 0 &&
					last_time_mentions < (int)twee.mentions.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showMentionsNotify && last_time_mentions > 0)
					show_popups(twee.mentions, last_time_mentions, exclude);
				
				last_time_mentions = (int)twee.mentions.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_mentions = last_time_mentions;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				mentions.load_string(template.generate_timeline(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				break;
		}
		
		updateAct.set_sensitive(true);
	}
	
	public Gee.ArrayList<string> show_popups(Gee.ArrayList<Status> lst, int last_time, owned Gee.ArrayList<string> exclude) {
		var tmpList = new GLib.List<Status>(); //list for new statuses
		
		foreach(Status status in lst) {
			if((int)status.created_at.mktime() > last_time)
				tmpList.append(status);
			else
				break;
		}
		tmpList.reverse();
		
		//show new statuses in time order
		foreach(Status new_status in tmpList) {
			if(!(new_status.id in exclude)) { //if not in exclude list
				exclude.add(new_status.id);
				
				if(new_status.user_screen_name != prefs.login) {
					var popup = new Notification(new_status.user_name,
						new_status.text, null, null);
				
					string av_path = template.cache.get_or_download(new_status.user_avatar, Cache.Method.ASYNC, false);
					if(av_path == new_status.user_avatar)
						popup.set_icon_from_pixbuf(logo);
					else {
						popup.set_icon_from_pixbuf(new Gdk.Pixbuf.from_file(av_path));
					}
					popup.set_timeout(2000); //doesn't working... hm
					popup.set_urgency(Notify.Urgency.NORMAL);
					popup.show();
				}
			}
		}
		
		tmpList = null;
		
		return exclude;
	}
	
	private void send_status() {
		var answer = twee.Reply.OK;
		reTweet.set_sensitive(false);
		
		if(reTweet.is_direct) {
			answer = twee.updateStatus(reTweet.text, reTweet.reply_id);
		} else {
			answer = twee.updateStatus(reTweet.text);
		}
		
		switch(answer) {
			case twee.Reply.ERROR_401:
				statusbar.set_status(statusbar.Status.ERROR_401);
				break;
			case twee.Reply.ERROR_TIMEOUT:
				statusbar.set_status(statusbar.Status.ERROR_TIMEOUT);
				break;
			case twee.Reply.ERROR_UNKNOWN:
				statusbar.set_status(statusbar.Status.ERROR_UNKNOWN);
				break;
			case twee.Reply.OK:
				refresh_action();
				reTweet.clear();
				reTweet.is_direct = false;
				reTweet.hide();
				reTweet.set_sensitive(true);
				break;
		}
	}
	
	private void before_close() {
		prefs.menuShow = menubar.visible;
		prefs.toolbarShow = toolbar.visible;
		
		prefs.write();
		main_quit();
	}
	*/
}
