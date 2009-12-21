using Gtk;

public class PrefDialog : Dialog {
	
	private Notebook tabs;
	private SpinButton updateInterval;
	private CheckButton showNotifications;
	private CheckButton roundedAvatars;
	private Entry login;
	private Entry password;
	private CheckButton savePass;
	
	public PrefDialog(Prefs prefs, Window parent) {
		this.modal = true;
		set_title("Preferences");
		this.has_separator = false;
		
		tabs = new Notebook();
		
		//main page
		var main_box = new VBox(false, 10);
		
		//update interval
		var upd_box = new HBox(false, 0);
		var updateLabel = new Label(_("Update interval"));
		updateInterval = new SpinButton.with_range(1, 60, 1);
		upd_box.pack_start(updateLabel, false, true, 10);
		upd_box.pack_start(updateInterval, true, true, 10);
		
		//show notifications
		var not_box = new HBox(false, 0);
		showNotifications = new CheckButton.with_label(_("Show notifications"));
		not_box.pack_start(showNotifications, false, true, 10);
		
		//rounded userpics
		var ava_box = new HBox(false, 0);
		roundedAvatars = new CheckButton.with_label(_("Rounded userpics"));
		ava_box.pack_start(roundedAvatars, false, true, 10);
		
		main_box.pack_start(upd_box, false, true, 10);
		main_box.pack_start(not_box, false, true, 0);
		main_box.pack_start(ava_box, false, true, 0);
		
		//account page
		var ac_box = new VBox(false, 0);
		
		//login
		var log_box = new HBox(false, 0);
		var logLabel = new Label(_("Login"));
		login = new Entry();
		log_box.pack_start(logLabel, false, true, 10);
		log_box.pack_end(login, false, true, 10);
		
		//password
		var pas_box = new HBox(false, 0);
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
		
		pas_box.pack_start(pasLabel, false, true, 10);
		pas_box.pack_end(password, false, true, 10);
		
		//save password
		var sa_box = new HBox(false, 0);
		savePass = new CheckButton.with_label(_("Remember password"));
		savePass.active = true;
		
		savePass.toggled.connect(() => {
			//
		});
		
		sa_box.pack_start(savePass, false, true, 10);
		
		ac_box.pack_start(log_box, false, true, 10);
		ac_box.pack_start(pas_box, false, true, 0);
		ac_box.pack_start(sa_box, false, true, 10);
		
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
		
		tabs.append_page(main_box, new Label(_("Main")));
		tabs.append_page(ac_box, new Label(_("Account")));
		
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
	
	private void setup_prefs(Prefs prefs) {
		updateInterval.value = prefs.updateInterval;
		showNotifications.active = prefs.showNotifications;
		roundedAvatars.active = prefs.roundedAvatars;
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
		
		showNotifications.toggled.connect(() => {
			prefs.showNotifications = showNotifications.active;
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