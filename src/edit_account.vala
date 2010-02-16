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
	
	private bool edit_mode;
	public bool ok = false;
	
	public EditAccount(Window _parent) {
		acc = new Account();
		parent = _parent;
		set_transient_for(parent);
		
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
		
		var password_label = new Label(_("Password"));
		password = new Entry();
		password.visible = 0;
		
		var service_label = new Label(_("Service"));
		service = new ComboBox.text();
		service.append_text("twitter.com"); //0
		service.append_text("identi.ca"); //1
		service.set_active(0);
		
		HigTable table = new HigTable(_("Account"));
		table.add_two_widgets(login_label, login);
		table.add_two_widgets(password_label, password);
		table.add_two_widgets(service_label, service);
		
		vbox.pack_start(table, true, true, 10);
		
		//action buttons
		add_button(STOCK_CANCEL, ResponseType.CANCEL);
		add_button(STOCK_OK, ResponseType.OK);
		
		response.connect(response_act);
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
		}
	}
	
	private string service_from_box(int index) {
		switch(index) {
			case 0:
				return "twitter.com";
				
			case 1:
				return "identi.ca";
			
			default:
				return "twitter.com";
		}
	}
	
	private void response_act(int resp_id) {
		switch(resp_id) {
			case ResponseType.OK:
				if(login.text.length > 0 && password.text.length > 0) {
					acc.login = login.text;
					acc.password = password.text;
					acc.service = service_from_box(service.active);
					
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
