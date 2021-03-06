/* edit_account.vala
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

public class EditAccount : Dialog {
	
	private Window parent;
	public Account acc;
	
	public Entry login;
	public Entry password;
	public ComboBox service;
	public Entry proxy;
	
	private bool edit_mode;
	public bool ok = false;
	
	//private Regex re_proxy;
	
	public EditAccount(Window _parent) {
		acc = new Account();
		parent = _parent;
		set_transient_for(parent);
		
		//re_proxy = new Regex();
		
		edit_mode = false;
		gui_setup();
		
		show_all();
	}
	
	public EditAccount.with_acc(Window _parent, Account _acc) {
		parent = _parent;
		acc = _acc;
		set_transient_for(parent);
		
		edit_mode = true;
		gui_setup();
		
		show_all();
		data_setup();
	}
	
	private void gui_setup() {
		modal = true;
		has_separator = false;
		
		if(edit_mode)
			set_title(_("Edit account"));
		else
			set_title(_("Create new account"));
		
		var login_label = new Label(_("Login"));
		login = new Entry();
		login.key_press_event.connect(on_enter);
		
		var password_label = new Label(_("Password"));
		password = new Entry();
		password.key_press_event.connect(on_enter);
		password.visible = 0;
		
		var service_label = new Label(_("Service"));
		service = new ComboBox.text();
		service.append_text("twitter.com"); //0
		service.append_text("identi.ca"); //1
		service.append_text("other"); //2
		service.changed.connect(() => {
			if(service.active == 2) //other
				proxy.set_sensitive(true);
			else
				proxy.set_sensitive(false);
		});
		
		service.set_active(0);
		
		var proxy_label = new Label(_("API proxy or other service"));
		var help_label = new Label("");
		help_label.set_markup("<small>(http://example.com/api/)</small>");
		proxy = new Entry();
		proxy.set_sensitive(false);
		proxy.key_press_event.connect(on_enter);
		var vp = new VBox(false, 0);
		vp.pack_start(proxy, false, false, 0);
		vp.pack_start(help_label, false, false, 0);
		var lp = new VBox(false, 0);
		lp.pack_start(proxy_label, false, false, 0);
		
		HigTable table = new HigTable(_("Account"));
		table.add_two_widgets(login_label, login);
		table.add_two_widgets(password_label, password);
		table.add_two_widgets(service_label, service);
		table.add_two_widgets(lp, vp);
		
		vbox.pack_start(table, true, true, 10);
		
		//action buttons
		add_button(STOCK_CANCEL, ResponseType.CANCEL);
		var cb = add_button(STOCK_OK, ResponseType.OK);
		
		response.connect(response_act);
		
		set_default(cb);
	}
	
	private void data_setup() {
		if(acc == null)
			return;
		
		login.set_text(acc.login);
		password.set_text(acc.password);
		
		switch(acc.service) {
			case "twitter.com":
				service.set_active(0);
				break;
			
			case "identi.ca":
				service.set_active(1);
				break;
			
			case "other":
				service.set_active(2);
				break;
		}
		
		proxy.set_text(acc.proxy);
	}
	
	/* when user pressed Enter key */
	private bool on_enter(Gdk.EventKey event) {
		if(event.hardware_keycode == 36) {
			response_act(ResponseType.OK);
			return true;
		} else
			return false;
	}
	
	private string service_from_box(int index) {
		switch(index) {
			case 0:
				return "twitter.com";
				
			case 1:
				return "identi.ca";
			
			case 2:
				return "other";
			
			default:
				return "twitter.com";
		}
	}
	
	private void response_act(int resp_id) {
		switch(resp_id) {
			case ResponseType.OK:
				if(login.text.length > 0 && password.text.length > 0) {
					if(service.active == 2) { //validation for proxy url
						if(proxy.text.length < 10) {
							var message_dialog = new MessageDialog(parent,
							Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
							Gtk.MessageType.INFO, Gtk.ButtonsType.OK, (_("You must enter a proxy address")));
		
							message_dialog.run();
							message_dialog.destroy();
							break;
						}
						
						if(proxy.text.substring(proxy.text.length - 1, 1) != "/")
							proxy.text += "/";
						
						bool valid_url = Regex.match_simple("(http|https)://([\\S]+)/",
							proxy.text);
						if(!valid_url) {
							var message_dialog = new MessageDialog(parent,
							Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
							Gtk.MessageType.INFO, Gtk.ButtonsType.OK, (_("Proxy address must contain a valid url")));
		
							message_dialog.run();
							message_dialog.destroy();
							break;
						}
					}
					
					acc.login = login.text;
					acc.password = password.text;
					acc.service = service_from_box(service.active);
					acc.proxy = proxy.text;
					
					ok = true;
					close();
				} else {
					var message_dialog = new MessageDialog(parent,
					Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
					Gtk.MessageType.INFO, Gtk.ButtonsType.OK, (_("You must fill in all fields")));
		
					message_dialog.run();
					message_dialog.destroy();
				}
				
				break;
			
			case ResponseType.CANCEL:
				ok = false;
				close();
				break;
		}
	}
}
