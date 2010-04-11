/* main_window.vala
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
using WebKit;
using RestAPI;
using Auth;
//using OAuth;
using Soup;

#if(LIBINDICATE)
	using Indicate;
#endif

public class MainWindow : Window {
	
	unowned SList<RadioAction> list_group;
	
	private Action updateAct;
	private ToggleAction menuAct;
	private ToggleAction toolbarAct;
	private AccountAction accountAct;
	
	private TrayIcon tray;
	
	private Gdk.Pixbuf logo;
	private Gdk.Pixbuf logo_fresh;
	
	private Widget menubar;
	private Widget toolbar;
	private Menu popup;
	//private IconEntry searchEntry;
	private HBox sbox;
	
	private SystemStyle gtk_style;
	
	public TimelineList home;
	public TimelineList mentions;
	public TimelineDirectList direct;
	public UserInfoList user_info;
	
	public ReTweet re_tweet;
	public StatusbarSmart statusbar;
	
	//private TwitterInterface twee;
	private Cache cache;
	private Template template;
	
	private Prefs prefs;
	private Accounts accounts;
	private SmartTimer timer;
	
	private AuthData auth_data;
	
	private Popups notify;
	
	public bool first_show = true;
	private bool updating = false;
	
	public MainWindow() {
		logo = new Gdk.Pixbuf.from_file(Config.LOGO_PATH);
		logo_fresh = new Gdk.Pixbuf.from_file(Config.LOGO_FRESH_PATH);
		
		/** testing oauth
		string cons_key = "k6R1A0PPkmpRcThEdPF1Q";
		string cons_sec = "TKneXwqslxkbaR3RQGcvvvGU4Qk01qh8HAhRIMN74";
		string request_token_url = "https://api.twitter.com/oauth/request_token";
		string access_token_url = "https://twitter.com/oauth/access_token";
		string auth_url = "http://api.twitter.com/oauth/authorize?oauth_token=%s";
		
		Soup.SessionSync session = new Soup.SessionSync();
		Client client = new Client(Config.CONS_KEY, Config.CONS_SEC,
		SignatureMethod.HMAC_SHA1, session);
		
		/*
		client.fetch_request_token ("POST", request_token_url);
		warning(auth_url, client.request_token.lookup("oauth_token"));
		warning("input PIN");
		string? pin = stdin.read_line();
		warning(pin);
		client.fetch_access_token("POST", access_token_url, pin);
		warning("%s, %s", client.request_token.lookup("oauth_token"),
			client.request_token.lookup("oauth_token_secret"));
		
		string oauth_token = "18604056-PlBJS2DNHgixESyaW2bo99qD3iwIysec1ANB8QpBr";
		string oauth_token_secret = "9LGC6VqPrEfYqu5WByANcyr391oBaWcM2ubiKeSPjM";
		
		client.request_token.replace("oauth_token", oauth_token);
		client.request_token.replace("oauth_token_secret", oauth_token_secret);
		
		var table = new HashTable<string, string>(str_hash, str_equal);
		string signature = client.generate_signature("GET", "http://api.twitter.com/statuses/home_timeline.xml",
			oauth_token_secret, table);
		//signature = signature.substring(0, signature.length - 1);
		
		warning(signature);
		
		string auth_header = """OAuth realm="%s",oauth_consumer_key="%s",oauth_token="%s",oauth_signature_method="HMAC-SHA1",oauth_signature="%s",oauth_timestamp="%s",oauth_nonce="%s",oauth_version="1.0"""".printf("http://api.twitter.com/",
                Config.CONS_KEY, oauth_token, signature, client.timestamp,
                client.nonce);
        
        warning(auth_header);
        
        string h = client.generate_authorization("GET", "http://api.twitter.com/statuses/home_timeline.xml", "http://api.twitter.com");
        warning(h);
        
        Message message = new Message("GET", "http://api.twitter.com/statuses/home_timeline.xml");
        message.set_http_version (HTTPVersion.1_1);
        MessageHeaders headers = new MessageHeaders(MessageHeadersType.MULTIPART);
        headers.append("Authorization", h);
        
        message.request_headers = headers;
        
        session.send_message(message);
        warning((string)message.response_body.flatten().data);
		 end of testing */
		
		//getting settings
		prefs = new Prefs();
		
		accounts = new Accounts();
		accounts.active_changed.connect(() => {
			refresh_auth();
		});
		
		accounts.changed.connect((hash) => {
			var acc = accounts.get_current_account();
			string cur_hash = acc.login + acc.password + acc.proxy;
			
			if(cur_hash == hash)
				refresh_auth();
		});
		
		set_default_size (prefs.width, prefs.height);
		set_size_request(350, 300);
		
		//set window position
		if(prefs.left >= 0 && prefs.top >= 0)
			move(prefs.left, prefs.top);
		
		configure_event.connect((widget, event) => {
			//saving window size and position
			int x;
			int y;
			get_position(out x, out y);
			
			prefs.width = event.width;
			prefs.height = event.height;
			prefs.left = x;
			prefs.top = y;
			
			return false;
		});
		
		set_icon(logo);
		set_title(Config.APPNAME);
		
		destroy.connect(() => before_close());
		
		gtk_style = new SystemStyle(rc_get_style(this));
		this.map_event.connect((event) => {
			gtk_style = new SystemStyle(rc_get_style(this));
			return true;
		});
		
		cache = new Cache();
		//template setup
		template = new Template(prefs, accounts, gtk_style, cache);
		
		//home timeline
		home = new TimelineList(this, accounts, TimelineType.HOME,
			template, prefs.numberStatuses,
			Icon.new_for_string(Config.TIMELINE_PATH),
			Icon.new_for_string(Config.TIMELINE_FRESH_PATH), "HomeAct", _("Home timeline"),
			_("Show your home timeline"), true);
		
		//mentions
		mentions = new TimelineList(this, accounts, TimelineType.MENTIONS,
			template, prefs.numberStatuses,
			Icon.new_for_string(Config.MENTIONS_PATH),
			Icon.new_for_string(Config.MENTIONS_FRESH_PATH), "MentionsAct", _("Mentions"),
			_("Show mentions"));
		
		//direct messages
		direct = new TimelineDirectList(this, accounts,
			template, prefs.numberStatuses,
			Icon.new_for_string(Config.DIRECT_PATH),
			Icon.new_for_string(Config.DIRECT_FRESH_PATH), "DirectAct", _("Direct messages"),
			_("Show direct messages"));
		
		//user info
		user_info = new UserInfoList(this, accounts, template, prefs.numberStatuses,
			Icon.new_for_string(Config.USERPIC_PATH), "UserInfoAct",
			_("User info"), _("Show information about user"));
		
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
		user_info.act.set_group(home.act.get_group());
		
		//retweet widget
		re_tweet = new ReTweet(this, prefs, accounts, cache, gtk_style);
		re_tweet.status_updated.connect((status) => {
			home.insert_status(status);
		});
		
		menu_init();
		
		//set popup menu to the views
		home.popup = popup;
		mentions.popup = popup;
		direct.popup = popup;
		user_info.popup = popup;
		
		//tray setup
		tray = new TrayIcon(this, prefs, logo, logo_fresh);
		tray.set_visible(prefs.showTray);
		
		tray.popup = popup;
		prefs.showTrayChanged.connect(() => {
			tray.set_visible(prefs.showTray);
		});
		
		//hiding on closing main window
		delete_event.connect((event) => {
			if(!tray.visible) { //close pino, if tray is hided
				before_close();
				return true;
			}
			
			this.hide_on_delete();
			visible = false;
			return true;
		});
		
		re_tweet.sending_data.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.SENDING_DATA, msg);
		});
		
		re_tweet.data_sent.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
		
		re_tweet.data_error_sent.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_ERROR, msg);
		});
		
		home.nickto.connect((screen_name) => {
			re_tweet.set_nickto(screen_name);
		});
		mentions.nickto.connect((screen_name) => {
			re_tweet.set_nickto(screen_name);
		});
		direct.nickto.connect((screen_name) => {
			re_tweet.set_nickto(screen_name);
		});
		home.user_info.connect((screen_name) => {
			user_info.show_user(screen_name);
		});
		mentions.user_info.connect((screen_name) => {
			user_info.show_user(screen_name);
		});
		direct.user_info.connect((screen_name) => {
			user_info.show_user(screen_name);
		});
		user_info.user_info.connect((screen_name) => {
			user_info.show_user(screen_name);
		});
		home.retweet.connect((status) => {
			re_tweet.set_state_retweet(status);
		});
		mentions.retweet.connect((status) => {
			re_tweet.set_state_retweet(status);
		});
		user_info.retweet.connect((status) => {
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
		user_info.directreply.connect((screen_name) => {
			re_tweet.set_state_directreply(screen_name);
		});
		home.replyto.connect((status) => {
			re_tweet.set_state_reply(status);
		});
		mentions.replyto.connect((status) => {
			re_tweet.set_state_reply(status);
		});
		user_info.replyto.connect((status) => {
			re_tweet.set_state_reply(status);
		});
		home.deleted.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
		mentions.deleted.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
		direct.deleted.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
		user_info.start_fetch.connect(() => {
			statusbar.set_status(StatusbarSmart.StatusType.UPDATING);
		});
		user_info.end_fetch.connect(() => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_OK);
		});
		user_info.follow_event.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.DATA_SENT, msg);
		});
		
		//setup logging
		statusbar = new StatusbarSmart();
		home.start_update.connect((req) => statusbar.logging(req));
		mentions.start_update.connect((req) => statusbar.logging(req));
		direct.start_update.connect((req) => statusbar.logging(req));
		re_tweet.start_update.connect((req) => statusbar.logging(req));
		
		home.finish_update.connect(() => statusbar.logging(_("updated ")));
		mentions.finish_update.connect(() => statusbar.logging(_("updated ")));
		direct.finish_update.connect(() => statusbar.logging(_("updated ")));
		home.updating_error.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_ERROR, msg);
		});
		mentions.updating_error.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_ERROR, msg);
		});
		direct.updating_error.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_ERROR, msg);
		});
		user_info.updating_error.connect((msg) => {
			statusbar.set_status(StatusbarSmart.StatusType.FINISH_ERROR, msg);
		});
		
		VBox vbox = new VBox(false, 0);
		vbox.pack_start(menubar, false, false, 0);
		vbox.pack_start(toolbar, false, false, 0);
		//vbox.pack_start(sbox, false, false, 0);
		vbox.pack_start(home, true, true, 0);
		vbox.pack_start(mentions, true, true, 0);
		vbox.pack_start(direct, true, true, 0);
		vbox.pack_start(user_info, true, true, 0);
		vbox.pack_end(statusbar, false, false, 0);
		vbox.pack_end(re_tweet, false, false, 0);
		
		this.add(vbox);
		
		//show window
		if(!prefs.startMin || !prefs.showTray) {
			first_show = false;
			show_all();
			first_hide();
		}
		
		//hide menubar and toolbar if needed
		if(!prefs.menuShow)
			menuAct.set_active(false);
		if(!prefs.toolbarShow)
			toolbarAct.set_active(false);
		
		if(accounts.is_new)
			run_prefs();
		
		//notification popups
		notify = new Popups(prefs, accounts, cache, logo);
		
		//first_hide();
		
		//getting updates
		if(accounts.accounts.size > 0) {
			refresh_action();
		}
		
		style_set.connect((prev_style) => { //when gtk style is changing
			gtk_style.updateStyle(rc_get_style(this));
			template.refresh_gtk_style(gtk_style);
		});
		
		//start timer
		timer = new SmartTimer(prefs.updateInterval * 60);
		timer.timeout.connect(refresh_action);
	}
	
	public void first_hide() { //when starts minimized
		re_tweet.hide();
		mentions.hide();
		direct.hide();
		user_info.hide();
		user_info.set_empty();
		
		if(!prefs.menuShow)
			menubar.hide();
		if(!prefs.toolbarShow)
			toolbar.hide();
	}
	
	private void refresh_auth() {
		updateAct.set_sensitive(false);
		statusbar.set_status(StatusbarSmart.StatusType.UPDATING);
		
		re_tweet.update_auth();
		home.update_auth();
		mentions.update_auth();
		direct.update_auth();
		user_info.update_auth();
		
		statusbar.set_status(StatusbarSmart.StatusType.FINISH_OK);
		updateAct.set_sensitive(true);
	}
	
	private void menu_init() {	
		var actGroup = new ActionGroup("main");
		
		//file menu
		var fileMenu = new Action("FileMenu", "Pino", null, null);
		
		var createAct = new Action("FileCreate", _("New status"),
			_("Create new status"), STOCK_EDIT);
		createAct.activate.connect(() => { re_tweet.set_state_new(); });
		
		var createDirectAct = new Action("FileCreateDirect", _("New direct message"),
			_("Create new direct message"), null);
		createDirectAct.set_gicon(Icon.new_for_string(Config.DIRECT_REPLY_PATH));
		createDirectAct.activate.connect(() => {
			re_tweet.set_state_directreply("");
		});
		
		var showUserAct = new Action("ShowUser", _("Show user"),
			_("Show information about specified user"), null);
		showUserAct.activate.connect(() => {
			user_info.set_empty();
			user_info.act.activate();
		});
		
		var showFavoritesAct = new Action("ShowFavorites", _("Show favorites..."),
			null, null);
		showFavoritesAct.set_gicon(Icon.new_for_string(Config.FAVORITE_PATH));
		showFavoritesAct.activate.connect(() => {
			new FavoritesViewDialog(this, accounts, template);
		});
		
		updateAct = new Action("FileUpdate", _("Update timeline"),
			null, STOCK_REFRESH);
		updateAct.activate.connect(refresh_action);
		var quitAct = new Action("FileQuit", _("Quit"),
			null, STOCK_QUIT);
		quitAct.activate.connect(before_close);
		
		//edit menu
		var editMenu = new Action("EditMenu", _("Edit"), null, null);
		accountAct = new AccountAction();
		accountAct.set_accounts(accounts);
		var prefAct = new Action("EditPref", _("Preferences"),
			null, STOCK_PREFERENCES);
		prefAct.activate.connect(run_prefs);
		
		//view menu
		var viewMenu = new Action("ViewMenu", _("View"), null, null);
		
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
			about_dlg.set_copyright("© 2009-2010 troorl");
			
			about_dlg.set_transient_for(this);
			about_dlg.run();
			about_dlg.hide();
		});
		
		actGroup.add_action(fileMenu);
		actGroup.add_action_with_accel(createAct, "<Ctrl>N");
		actGroup.add_action_with_accel(createDirectAct, "<Ctrl>D");
		actGroup.add_action(showUserAct);
		actGroup.add_action(showFavoritesAct);
		actGroup.add_action_with_accel(updateAct, "<Ctrl>R");
		actGroup.add_action_with_accel(quitAct, "<Ctrl>Q");
		actGroup.add_action(editMenu);
		actGroup.add_action_with_accel(re_tweet.shortAct, "<Ctrl>U");
		actGroup.add_action(accountAct);
		actGroup.add_action_with_accel(prefAct, "<Ctrl>P");
		actGroup.add_action(viewMenu);
		actGroup.add_action_with_accel(home.act, "<Ctrl>1");
		actGroup.add_action_with_accel(mentions.act, "<Ctrl>2");
		actGroup.add_action_with_accel(direct.act, "<Ctrl>3");
		actGroup.add_action_with_accel(user_info.act, "<Ctrl>4");
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
					<separator />
					<menuitem action="ShowUser" />
					<menuitem action="ShowFavorites" />
					<separator />
					<menuitem action="FileUpdate" />
					<separator />
					<menuitem action="FileQuit" />
				</menu>
				<menu action="EditMenu">
					<menuitem action="UrlShort" />
					<menu action="AccountAct">
					</menu>
					<separator />
					<menuitem action="EditPref" />
				</menu>
				<menu action="ViewMenu">
					<menuitem action="HomeAct" />
					<menuitem action="MentionsAct" />
					<menuitem action="DirectAct" />
					<separator />
					<menuitem action="UserInfoAct" />
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
				<toolitem action="HomeAct" />
				<toolitem action="MentionsAct" />
				<toolitem action="DirectAct" />
				<separator />
				<toolitem action="UserInfoAct" />
				<separator expand="true" draw="false" />
				<toolitem action="AccountAct" />
			</toolbar>
		</ui>
		""";
		
		ui.add_ui_from_string(uiString, uiString.length);
		
		menubar = ui.get_widget("/MenuBar");
		popup = (Menu)ui.get_widget("/MenuPopup");
		toolbar = ui.get_widget("/ToolBar");
		
		accountAct.set_ui(ui, cache);
		//var toolitem = new AccountAction(accounts);
		//((Toolbar)toolbar).insert(toolitem, 9);
	}
	
	public void refresh_action() {
		updateAct.set_sensitive(false);
		
		statusbar.set_status(StatusbarSmart.StatusType.UPDATING);
		
		warning("start home");
		var home_list = home.update();
		warning("start mentions");
		var mentions_list = mentions.update();
		warning("start direct");
		var direct_list = direct.update();
		statusbar.set_status(StatusbarSmart.StatusType.FINISH_OK);
		warning("end of update, starting notification");
		notify.start(home_list, mentions_list, direct_list);
		warning("notification is ok");
		updateAct.set_sensitive(true);
	}
	
	private void run_prefs() {
		var pref_dialog = new PrefDialog(prefs, this, accounts);
		
		pref_dialog.delete_cache.connect(() => {
			cache.delete_cache();
		});
		
		pref_dialog.destroy.connect(() => {
			//timer interval update
			timer.set_interval(prefs.updateInterval * 60);
			prefs.write();
		});
		
		//pref_dialog.set_transient_for(this);
		//pref_dialog.show();
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
}
