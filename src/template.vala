using Gee;
using GLib;

class Template : Object
{
	private string mainTemplate;
	private string statusTemplate;
	private string statusMeTemplate;
	
	private Regex nicks;
	private Regex tags;
	private Regex urls;
	
	public Template()
	{
		reload();
		
		//compile regex
		nicks = new Regex("@([A-Za-z0-9_]+)");
		tags = new Regex("(\\#[A-Za-z0-9_]+)");
		urls = new Regex("((http|https|ftp)://([\\S]+))"); //need something better
	}
	
	public string generateFriends(Gee.ArrayList<Status> friends,
		SystemStyle gtkStyle, string nick)
	{
		string content = "";
		
		var now = get_current_time();
		
		foreach(Status i in friends)
		{
			//checking for new statuses
			var fresh = "old";
			if(i.unreaded)
				fresh = "fresh";
			
			//making human-readable time/date
			string time = time_to_human_delta(now, i.created_at);
			if(i.user_name == nick)
			{
				content += statusMeTemplate.printf(i.user_avatar,
					"me",
					i.id,
					time,
					//i.user_screen_name,
					//i.user_name,
					i.user_name,
					making_links(i.text),
					i.id
					);
			}
			else
			{
				content += statusTemplate.printf(i.user_avatar,
					fresh,
					i.id,
					i.user_name,
					i.user_name,
					time,
					making_links(i.text),
					i.user_name,
					i.id,
					i.user_screen_name,
					i.user_name
					);
			}
		}
		
		return mainTemplate.printf(gtkStyle.bg_color, //body background
			gtkStyle.fg_color, //main text color
			gtkStyle.fg_color, //nick color
			gtkStyle.lt_color, //date strings color
			gtkStyle.sl_color, //links color
			gtkStyle.lt_color, //reply link
			content);
	}
	
	private string making_links(string text)
	{
		string result = nicks.replace(text, -1, 0, "@<a class='re_nick' href='http:/twitter.com/\\1'>\\1</a>");
		//warning("NICK: %s", result);
		result = tags.replace(result, -1, 0, "<a class='tags' href=''>\\1</a>");
		result = urls.replace(result, -1, 0, "<a href='\\0'>\\0</a>");
		return result;
	}
	
	private string time_to_human_delta(Time now, Time t)
	{
		var delta = (int)(now.mktime() - t.mktime());
		if(delta < 30)
			return "a few seconds ago";
		if(delta < 120)
			return "1 minute ago";
		if(delta < 3600)
			return "%i minutes ago".printf(delta / 60);
		if(delta < 7200)
			return "about 1 hour ago";
		if(delta < 86400)
			return "about %i hours ago".printf(delta / 3600);
		
		return t.format("%k:%M %b %d %Y");
	}
	
	private Time get_current_time()
	{
		var tval = TimeVal();
		tval.get_current_time();
		return Time.local((time_t)tval.tv_sec);
		//warning("lolo %s", tr.to_string());
	}
	
	public void reload()
	{
		//load templates
		mainTemplate = loadTemplate(TEMPLATES_PATH + "/main.tpl");
		statusTemplate = loadTemplate(TEMPLATES_PATH + "/status.tpl");
		statusMeTemplate = loadTemplate(TEMPLATES_PATH + "/status_me.tpl");
	}
	
	private string loadTemplate(string path)
	{
		var file = File.new_for_path(path);
		if(!file.query_exists(null))
		{
			stderr.printf("File '%s' doesn't exist.\n", file.get_path());
			//return 1
		}
		var in_stream = new DataInputStream (file.read(null));
		
		string result = "";
		string tmp = "";
		while((tmp = in_stream.read_line(null, null)) != null)
			result += tmp;
		tmp = null;
		in_stream = null;
		return result;
	}
}