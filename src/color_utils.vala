using Gtk;

namespace ColorUtils {
	
	public string color2rgba(Gdk.Color color, double alpha = 0.40) { //alpha 0.0-1.0
		
		string alpha_string = alpha.to_string();
		switch(alpha_string) {
			case "0":
				alpha_string = "0.00";
				break;
			case "1":
				alpha_string = "1.00";
				break;
			default:
				alpha_string = alpha.to_string().substring(0, 4);
				break;
		}
		
		return "rgba(%d, %d, %d, %s)".printf(color.red/256, color.green/256,
			color.blue/256, alpha_string);
	}
	
	public Gdk.Color rgba2color(string rgba, out uint16 alpha) {
		Gdk.Color color = Gdk.Color();
		
		Regex re = new Regex("rgba\\(([0-9]+), ([0-9]+), ([0-9]+), ([0-9]\\.[0-9][0-9])\\)");
		color.red = (uint16)re.replace(rgba, -1, 0, "\\1").to_int() * 256;
		color.green = (uint16)re.replace(rgba, -1, 0, "\\2").to_int() * 256;
		color.blue = (uint16)re.replace(rgba, -1, 0, "\\3").to_int() * 256;
		alpha = (uint16)(re.replace(rgba, -1, 0, "\\4").to_double() * 256.0 * 256.0);
		//warning("%d", alpha);
		return color;
	}
	
	public string rgb_to_hex(Gdk.Color color) {
		string s = "%X%X%X".printf(
			(int)Math.trunc(color.red / 256.00),
			(int)Math.trunc(color.green / 256.00),
			(int)Math.trunc(color.blue / 256.00));
		return "#" + s;
	}
	
	public uint16 lighter(uint16 color, uint16 delta) {
		if(color + delta > 255*256)
			return 255*256;
		else
			return color + delta; 
	}
	
	public uint16 darker(uint16 color, uint16 delta) {
		if(color - delta < 0)
			return 0;
		else
			return color - delta; 
	}
}
