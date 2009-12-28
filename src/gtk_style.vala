/* gtk_style.vala
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
		warning("lt_color: %s", lt_color);
		warning("New style");
	}
	
	private uint16 lighter(uint16 color, uint16 delta) {
		if(color + delta > 255*256)
			return 255*256;
		else
			return color + delta; 
	}
	
	private string rgb_to_hex(Gdk.Color color) {
		string s = "%X%X%X".printf(
			(int)Math.trunc(color.red / 256.00),
			(int)Math.trunc(color.green / 256.00),
			(int)Math.trunc(color.blue / 256.00));
		return "#" + s;
	}
}