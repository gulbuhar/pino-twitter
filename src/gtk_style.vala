/* gtk_style.vala
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

using ColorUtils;

public class SystemStyle : Object {
	
	private string _bg_color;
	public string bg_color{get{return _bg_color;}}
	
	private string _fg_color;
	public string fg_color{get{return _fg_color;}}
	
	private string _sl_color;
	public string sl_color{get{return _sl_color;}}
	
	private string _lg_color;
	public string lg_color{get{return _lg_color;}}
	
	private string _lt_color;
	public string lt_color{get{return _lt_color;}}
	
	private string _dr_color;
	public string dr_color{get{return _dr_color;}}
	
	public SystemStyle(Gtk.Style style) {
		updateStyle(style);
	}
	
	public void updateStyle(Gtk.Style style) {
		_bg_color = rgb_to_hex(style.bg[Gtk.StateType.NORMAL]);
		_lg_color = rgb_to_hex(style.light[Gtk.StateType.NORMAL]);
		_fg_color = rgb_to_hex(style.fg[Gtk.StateType.NORMAL]);
		_sl_color = rgb_to_hex(style.bg[Gtk.StateType.SELECTED]);
		
		//working on light color (lt_color)
		{
			var light_color = Gdk.Color();
			light_color.red = lighter(style.fg[Gtk.StateType.NORMAL].red, 100*256);
			light_color.green = lighter(style.fg[Gtk.StateType.NORMAL].green, 100*256);
			light_color.blue = lighter(style.fg[Gtk.StateType.NORMAL].blue, 100*256);
			_lt_color = rgb_to_hex(light_color);
			
		}
		
		// working on dr_color
		{
			var dark_color = Gdk.Color();
			dark_color.red = darker(style.bg[Gtk.StateType.NORMAL].red, 20*256);
			dark_color.green = darker(style.bg[Gtk.StateType.NORMAL].green, 20*256);
			dark_color.blue = darker(style.bg[Gtk.StateType.NORMAL].blue, 20*256);
			_dr_color = rgb_to_hex(dark_color);
		}
		
		//warning("New style");
	}
}
