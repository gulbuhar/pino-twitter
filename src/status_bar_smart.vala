/* status_bar_smart.vala
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
using TimeUtils;

public class StatusbarSmart : VBox {
	public static enum StatusType {
		UPDATING,
		SENDING_DATA,
		FINISH_OK,
		FINISH_ERROR
	}
	
	private HSeparator sep;
	private Image img;
	private Label label;
	
	private bool warning = false;
	
	public StatusbarSmart() {
		sep = new HSeparator();
		img = new Image();
		label = new Label("");
		
		var event_img = new EventBox();
		event_img.add(img);
		event_img.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		event_img.button_press_event.connect(log_click);
		
		var hbox = new HBox(false, 5);
		hbox.pack_start(event_img, false, false, 0);
		hbox.pack_start(label, false, false, 0);
		
		pack_start(sep, false, false, 0);
		pack_start(hbox, false, false, 0);
	}
	
	private bool log_click(Gdk.EventButton event) {
		if(event.button == 1) {
			LogWindow log_window = new LogWindow(log);
			log_window.show_all();
		}
		
		return false;
	}
	
	private void push(string icon, string text) {
		img.set_from_stock(icon, Gtk.IconSize.MENU);
		label.set_label(text);
	}
	
	private void push_custom(string icon_path, string text) {
		Gdk.PixbufAnimation anima = new Gdk.PixbufAnimation.from_file(icon_path);
		img.set_from_animation(anima);
		label.set_label(text);
	}
	
	private string log = "";
	
	public void log_warning(string line) {
		warning = true;
		logging(line);
	}
	
	public void logging(string line) {
		log += "[%s] %s\n".printf(get_current_time().format("%b %d %k:%M:%S"), line);
	}
	
	public void set_status(StatusType status_type, string message = "") {
		switch(status_type) {
			case StatusType.FINISH_OK:
				if(warning) {
					push("gtk-dialog-warning", _("updated "));
					warning = false;
				} else {
					push("gtk-apply", _("updated "));
				}
				break;
			
			case StatusType.UPDATING:
				push_custom(Config.PROGRESS_PATH, _("updating... "));
				break;
			
			case StatusType.SENDING_DATA:
				push("gtk-go-up", _("sending status... "));
				break;
			
			case StatusType.FINISH_ERROR:
				push("gtk-dialog-warning", message);
				break;
		}
	}
}
