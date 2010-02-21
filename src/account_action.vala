/* account_action.vala
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

public class AccountAction : Action {
	
	private Accounts accounts;
	private MenuItem menu_item;
	private ToolButton tool_item;
	private Icon default_icon;
	private Menu menu;
	
	private RestAPIAcc api;
	private Cache cache;
	
	weak Thread thread_1;
	
	public AccountAction() {
		name = "AccountAct";
		label = _("Accounts");
		tooltip = null;
		stock_id = null;
		
		default_icon = Icon.new_for_string(Config.USERPIC_PATH);
		set_gicon(default_icon);
	}
	
	/* set item linked with this action */
	public void set_ui(UIManager ui, Cache _cache) {
		menu_item = (MenuItem)ui.get_widget("/MenuBar/EditMenu/AccountAct");
		tool_item = (ToolButton)ui.get_widget("/ToolBar/AccountAct");
		
		cache = _cache;
		
		setup();
		
		
		tool_item.clicked.connect(() => {
			menu.popup(null, null, null, 1, 0);
		});
	}
	
	/* setup accounts in submenu */
	private void setup() {
		menu = new Menu();
		
		unowned SList<RadioMenuItem> group = null;
		
		foreach(Account acc in accounts.accounts) {
			RadioMenuItem item = new RadioMenuItem.with_label(group,
				"%s (%s)".printf(acc.login, acc.service));
			group = item.get_group();
			item.active = acc.active;
			
			item.toggled.connect(() => {
				if(item.active) {
					accounts.set_active_account(acc.login + acc.service);
					accounts.write();
				}
			});
			
			menu.append(item);
		}
		
		menu_item.set_submenu(menu);
		menu.show_all();
	}
	
	private void icon_setup() {
	
	}
	
	public void set_accounts(Accounts _accounts) {
		accounts = _accounts;
		var acc = accounts.get_current_account();
		api = new RestAPIAcc(acc);
		accounts.changed.connect(() => {
			setup();
		});
		
		accounts.active_changed.connect(() => {
			var accc = accounts.get_current_account();
			api.set_auth(accc);
			update_icon();
			tooltip = "%s (%s)".printf(accc.login, accc.service);
		});
		
		update_icon();
		tooltip = "%s (%s)".printf(acc.login, acc.service);
	}
	
	public void update_icon() {
		if (!Thread.supported()) {
			error("Cannot run without threads.");
			return;
		}
		
		try {
			thread_1 = Thread.create(get_userpic, false);
		} catch(ThreadError e) {
			warning("Error: %s", e.message);
			return;
        }
	}
	
	private void *get_userpic() {
		string? url = api.get_userpic_url();
		
		if(url == null) {
			set_gicon(default_icon);
			return null;
		}
		
		string path = cache.get_or_download(url, Cache.Method.SYNC, true);
		
		Icon icon = Icon.new_for_string(path);
		set_gicon(icon);
		
		return null;
	}
}
