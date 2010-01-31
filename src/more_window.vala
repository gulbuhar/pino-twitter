/* more_window.vala
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

public class MoreWindow : Window {
	
	ToolButton button;
	
	public signal void moar_event();
	
	public MoreWindow() {
		type = WindowType.POPUP;
		
		//set_position(WindowPosition.MOUSE);
		
		button = new ToolButton.from_stock(STOCK_GO_DOWN);
		button.set_tooltip_text(_("Get older entries"));
		button.set_size_request(40, 40);
		button.clicked.connect(() => moar_event());
		HBox hbox = new HBox(false, 0);
		hbox.pack_start(button, false, false, 0);
		add(hbox);
	}
	
	public void show_at(int x, int y) {
		move(x, y);
		show_all();
	}
	
	public void set_enabled(bool huh) {
		button.set_sensitive(huh);
	}
}
