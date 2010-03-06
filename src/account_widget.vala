/* account_widget.vala
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

public class AccountWidget : HBox {
	
	private TreeView table;
	private Button add_button;
	private Button edit_button;
	private Button delete_button;
	
	ListStore model;
	
	private Window parent;
	private Accounts accounts;
	
	public AccountWidget(Window _parent, Accounts _accounts) {
		parent = _parent;
		accounts = _accounts;
		
		//gui setup
		homogeneous = false;
		spacing = 4;
		
		table = new TreeView();
		var frame = new Frame(null);
		frame.add(table);
		
		HBox tbl_box = new HBox(true, 0);
		tbl_box.pack_start(frame, true, true, 0);
		VBox tvbox = new VBox(true, 0);
		tvbox.pack_start(tbl_box, true, true, 0);
		
		add_button = new Button.from_stock("gtk-add");
		add_button.clicked.connect(add_event);
		edit_button = new Button.from_stock("gtk-edit");
		edit_button.clicked.connect(edit_event);
		delete_button = new Button.from_stock("gtk-delete");
		delete_button.clicked.connect(delete_event);
		
		VBox btn_box = new VBox(false, 4);
		btn_box.pack_start(add_button, false, false, 0);
		btn_box.pack_start(edit_button, false, false, 0);
		btn_box.pack_start(delete_button, false, false, 0);
		
		pack_start(tvbox, true, true, 0);
		pack_end(btn_box, false, false, 0);
		
		//list model setup
		model = new ListStore(3, typeof(string), typeof(string), typeof(string));
		table.set_model(model);
		table.get_selection().set_mode(SelectionMode.SINGLE);
		select_first();
		
		table.insert_column_with_attributes(-1, _("Login"), new CellRendererText(), "text", 0);
		table.insert_column_with_attributes(-1, _("Service"), new CellRendererText(), "text", 1);
		table.insert_column_with_attributes(-1, _("API proxy"), new CellRendererText(), "text", 2);
		
		table_setup();
		
		table.cursor_changed.connect(() => {
			edit_button.set_sensitive(true);
			delete_button.set_sensitive(true);
		});
	}
	
	/* select first item in table */
	private void select_first() {
		TreeIter iter;
		if(model.get_iter_first(out iter)) {
			table.get_selection().select_iter(iter);
		} else {
			edit_button.set_sensitive(false);
			delete_button.set_sensitive(false);
		}
	}
	
	/* edit account */
	private void edit_event() {
		TreeIter iter;
		TreeModel tmp_model;
		table.get_selection().get_selected(out tmp_model, out iter);
		
		Value login;
		Value service;
		Value proxy;
		
		tmp_model.get_value(iter, 0, out login);
		tmp_model.get_value(iter, 1, out service);
		tmp_model.get_value(iter, 2, out proxy);
		
		var acc = accounts.get_by_hash((string)login + (string)service + (string)proxy);
		
		var edit_dialog = new EditAccount.with_acc(parent, acc);
		edit_dialog.destroy.connect(() => {
			if(edit_dialog.ok) {
				warning(edit_dialog.acc.login);
				model.set_value(iter, 0, acc.login);
				model.set_value(iter, 1, acc.service);
				model.set_value(iter, 2, acc.proxy);
				
				string hash = acc.login + acc.password + acc.proxy;
				
				accounts.changed(hash);
				
				accounts.write();
			}
		});
	}
	
	/* create new account */
	private void add_event() {
		var edit_dialog = new EditAccount(parent);
		edit_dialog.destroy.connect(() => {
			if(edit_dialog.ok) { //create new account
				accounts.add_account(edit_dialog.acc);
				accounts.write();
				
				//add entry to the table
				TreeIter iter;
				model.append(out iter);
				model.set(iter, 0, edit_dialog.acc.login, 1, edit_dialog.acc.service);
				table.get_selection().select_iter(iter);
				table.cursor_changed();
				
				//accounts.changed();
				
				if(accounts.accounts.size == 1)
					accounts.active_changed();
			}
		});
	}
	
	/* delete account */
	private void delete_event() {
		var message_dialog = new MessageDialog(parent,
			Gtk.DialogFlags.DESTROY_WITH_PARENT | Gtk.DialogFlags.MODAL,
			Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
			(_("Sure you want to delete this account?")));
		
		if(message_dialog.run() != ResponseType.YES) {
			message_dialog.destroy();
			return;
		}
		
		message_dialog.destroy();
		
		TreeIter iter;
		TreeModel tmp_model;
		table.get_selection().get_selected(out tmp_model, out iter);
		
		Value login;
		Value service;
		Value proxy;
		
		tmp_model.get_value(iter, 0, out login);
		tmp_model.get_value(iter, 1, out service);
		tmp_model.get_value(iter, 2, out proxy);
		
		string hash = (string)login + (string)service + (string)proxy;
		var acc = accounts.get_by_hash(hash);
		bool was_active = acc.active; //if we delete active account
		
		accounts.delete_account(hash);
		accounts.write();
		
		model.remove(iter);
		
		select_first();
		
		//accounts.changed(hash);
		
		if(was_active)
			accounts.active_changed();
	}
	
	/* insert data to the table */
	private void table_setup() {
		TreeIter iter;
		
		foreach(Account acc in accounts.accounts) {
			model.append(out iter);
			model.set(iter, 0, acc.login, 1, acc.service, 2, acc.proxy);
		}
	}
}
