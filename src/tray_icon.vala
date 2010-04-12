/* tray_icon.vala
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

public class TrayIcon : StatusIcon {
	
	private MainWindow parent;
	private Prefs prefs;
	private Gdk.Pixbuf logo;
	private Gdk.Pixbuf logo_fresh;
	
	private Menu _popup;
	public Menu popup {
		get{ return popup; }
		set{ _popup = value; }
	}
	
	public TrayIcon(MainWindow _parent, Prefs _prefs, Gdk.Pixbuf _logo,
		Gdk.Pixbuf _logo_fresh) {
		
		base;
		
		parent = _parent;
		prefs = _prefs;

		var theme = IconTheme.get_default();
		
		if(!theme.has_icon("pino-tray-icon")) {
			warning("no!!!!!!!!");
			logo = _logo;
		} else {
			var info = theme.lookup_icon("pino-tray-icon", 22, IconLookupFlags.USE_BUILTIN);
			logo = info.load_icon();
		}
		
		if(!theme.has_icon("pino-tray-icon")) {
			warning("no!!!!!!!!");
			logo_fresh = _logo_fresh;
		} else {
			var info = theme.lookup_icon("pino-tray-icon-fresh", 22, IconLookupFlags.USE_BUILTIN);
			logo_fresh = info.load_icon();
		}
		
		
		set_from_pixbuf(logo);
		parent.set_icon(logo);
		
		set_tooltip_text(_("%s - not only a twitter client").printf(Config.APPNAME));
		
		popup_menu.connect((button, activate_time) => {
			_popup.popup(null, null, null, button, activate_time);
		});
		
		activate.connect(() => {
			if(parent.visible) {
				parent.hide();
			} else {
				if(parent.first_show) {
					parent.show_all();
					parent.first_hide();
					parent.first_show = false;
					return;
				}
				
				parent.show();
				parent.move(prefs.left, prefs.top);
			}
		});
		
		#if(LIBINDICATE)
			var server = Indicate.Server.ref_default();
			
			server.set_type("message.pino");
			server.set_desktop_file(Config.DESKTOP_FILE_PATH);
			server.server_display.connect(dirty_activate);
			server.show();
			
			/*
			indicator = new Indicate.Indicator();
			indicator.set_property("subtype", "pino");
			indicator.set_property("sender", "troorl");
			indicator.set_property("body", "bla bla bla");
			indicator.user_display.connect(dirty_activate);
			indicator.show();
			*/
		#endif
		
	}

	private void dirty_activate() {
		try {
			Process.spawn_async(null, {Config.APP_PATH, "/"}, null,
				GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
		} catch(GLib.SpawnError e) {
			warning(e.message);
		}
	}
	
	public void new_tweets(bool y) {
		if(y) {
			set_from_pixbuf(logo_fresh);
			parent.set_icon(logo_fresh);
		}
		else {
			set_from_pixbuf(logo);
			parent.set_icon(logo);
		}
	}
}
