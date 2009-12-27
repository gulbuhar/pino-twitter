using Gtk;
using WebKit;
//using Sexy;
using Notify;

public class MainWindow : Window {
	
	private Action updateAct;
	private ToggleAction menuAct;
	private ToggleAction toolbarAct;
	private StatusIcon tray;
	
	private Gdk.Pixbuf logo;
	
	private Widget menubar;
	private Widget toolbar;
	private Menu popup;
	//private IconEntry searchEntry;
	private HBox sbox;
	
	private SystemStyle gtkStyle;
	
	private WebView tweets;
	ScrolledWindow scroll_tweets;
	private WebView mentions;
	ScrolledWindow scroll_mentions;
	private ReTweet reTweet;
	private StatusbarSmart statusbar;
	
	private TwitterInterface twee;
	private Template template;
	
	private Prefs prefs;
	private SmartTimer timer;
	
	private int last_time_friends = 0;
	private int last_focused_friends = -1;
	private int last_time_mentions = 0;
	private int last_focused_mentions = -1;
	
	private bool focused;
	
	public MainWindow() {
		logo = new Gdk.Pixbuf.from_file(Config.LOGO_PATH);
		
		//getting settings
		prefs = new Prefs();
		prefs.roundedAvatarsChanged.connect(() => {
			tweets.load_string(template.generateFriends(twee.friends, gtkStyle, prefs, last_focused_friends),
				"text/html", "utf8", "file:///");
			mentions.load_string(template.generateFriends(twee.mentions, gtkStyle, prefs, last_focused_mentions),
				"text/html", "utf8", "file:///");
		});
		
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
		
		this.map_event.connect(get_colors);
		this.style_set.connect(style_update);
		
		//tray setup
		tray = new StatusIcon.from_pixbuf(logo);
		tray.activate.connect(tray_activate);
		tray.popup_menu.connect(tray_popup);
		tray.set_tooltip_text(_("%s - a twitter client").printf(Config.APPNAME));
		
		//widgets setup
		/*	
		searchEntry = new IconEntry();
		searchEntry.key_press_event.connect(search_hide_action);
		searchEntry.set_icon(IconEntryPosition.PRIMARY,
			new Gtk.Image.from_stock("gtk-find", Gtk.IconSize.SMALL_TOOLBAR));
		sbox = new HBox(false, 0);
		sbox.pack_end(searchEntry, false, false, 0);
		*/
		
		//template setup
		template = new Template();
		
		//timeline
		tweets = new WebView();
		tweets.can_go_back_or_forward(0);
		tweets.navigation_policy_decision_requested.connect(link_clicking);
		tweets.button_press_event.connect(show_popup_menu);
		scroll_tweets = new ScrolledWindow(null, null);
        scroll_tweets.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll_tweets.add(tweets);
		
		//mentions
		mentions = new WebView();
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
		
		menu_init();
		
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
				
				refresh_action();
			}
			
			prefs.is_new = false;
		});
		
		pref_dialog.set_transient_for(this);
		pref_dialog.show();
	}
	
	private void tray_activate() {
		if(visible) {
			this.hide();
			visible = false;
		} else {
			this.show();
			visible = true;
		}
	}
	
	private void tray_popup(uint button, uint activate_time) {
		popup.popup(null, null, null, button, activate_time);
	}
	
	private bool show_popup_menu(Gdk.EventButton event) {
		if((event.type == Gdk.EventType.BUTTON_PRESS) && (event.button == 3)) {
			warning("Popup");
			popup.popup(null, null, null, event.button, event.time);
			return true;
		}
		
		return false;
	}
	
	private bool get_colors(Gdk.Event event) {
		gtkStyle = new SystemStyle(rc_get_style(this));
		return true;
	}
	
	private void style_update(Style? prevStyle) {
		gtkStyle.updateStyle(rc_get_style(this));
		tweets.load_string(template.generateFriends(twee.friends, gtkStyle, prefs, last_focused_friends),
			"text/html", "utf8", "file:///");
		mentions.load_string(template.generateFriends(twee.mentions, gtkStyle, prefs, last_focused_mentions),
			"text/html", "utf8", "file:///");
		//warning("Style changed!");
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
				var reply = twee.retweetStatus(status_id);
				status_actions(reply);
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
				tweets.load_string(template.generateFriends(twee.friends, gtkStyle, prefs, last_focused_friends),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_friends > 0 &&
					last_time_friends < (int)twee.friends.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showTimelineNotify && last_time_friends > 0)
					show_popups(twee.friends, last_time_friends);
				
				last_time_friends = (int)twee.friends.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_friends = last_time_friends;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				tweets.load_string(template.generateFriends(twee.friends, gtkStyle, prefs, last_focused_friends),
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
				mentions.load_string(template.generateFriends(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				
				//tray notification
				if(last_time_mentions > 0 &&
					last_time_mentions < (int)twee.mentions.get(0).created_at.mktime() &&
					!focused) {
					tray.set_from_file(Config.LOGO_FRESH_PATH);
				}
				
				//show new statuses via libnotify
				if(prefs.showMentionsNotify && last_time_mentions > 0)
					show_popups(twee.mentions, last_time_mentions);
				
				last_time_mentions = (int)twee.mentions.get(0).created_at.mktime();
				if(focused || last_focused_friends == -1)
					last_focused_mentions = last_time_mentions;
				
				break;
			case TwitterInterface.Reply.EMPTY:
				mentions.load_string(template.generateFriends(twee.mentions, gtkStyle, prefs, last_focused_mentions),
					"text/html", "utf8", "file:///");
				break;
		}
		
		updateAct.set_sensitive(true);
	}
	
	public void show_popups(Gee.ArrayList<Status> lst, int last_time) {
		var tmpList = new GLib.List<Status>(); //list for new statuses
		
		foreach(Status status in lst) {
			if((int)status.created_at.mktime() > last_time)
				tmpList.append(status);
			else
				break;
		}
		tmpList.reverse();
		
		//show new statuses in time order
		foreach(Status newStatus in tmpList) {
			
			if(newStatus.user_screen_name != prefs.login) {
				var popup = new Notification(newStatus.user_name,
					newStatus.text, null, null);
				popup.set_icon_from_pixbuf(logo);
				popup.set_timeout(2000); //doesn't working... hm
				popup.set_urgency(Notify.Urgency.LOW);
				popup.show();
			}
		}
		
		tmpList = null;
		//warning("end notification");
	}
	
	/*
	private void search_show_action()
	{
		searchEntry.show();
		this.set_focus(searchEntry);
	}
	
	private bool search_hide_action(Gdk.EventKey event)
	{
		if(event.hardware_keycode == 9) //esc key
		{
			searchEntry.hide();
		}
		return false;
	}
	*/
	
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
}