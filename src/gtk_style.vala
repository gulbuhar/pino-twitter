public class SystemStyle : Object
{
	private string _bg_color;
	public string bg_color{get{return _bg_color;}}
	private string _fg_color;
	public string fg_color{get{return _fg_color;}}
	private string _sl_color;
	public string sl_color{get{return _sl_color;}}
	private string _lt_color;
	public string lt_color{get{return _lt_color;}}
	
	public SystemStyle(Gtk.Style style)
	{
		updateStyle(style);
	}
	
	public void updateStyle(Gtk.Style style)
	{
		_bg_color = rgb_to_hex(style.bg[Gtk.StateType.NORMAL]);
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
	
	private uint16 lighter(uint16 color, uint16 delta)
	{
		if(color + delta > 255*256)
			return 255*256;
		else
			return color + delta; 
	}
	
	private string rgb_to_hex(Gdk.Color color)
	{
		string s = "%X%X%X".printf(
			(int)Math.trunc(color.red / 256.00),
			(int)Math.trunc(color.green / 256.00),
			(int)Math.trunc(color.blue / 256.00));
		return "#" + s;
	}
}