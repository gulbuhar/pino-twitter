using Notify;
using Gee;
using RestAPI;

public class Popups : Object {
	
	private Prefs prefs;
	private Cache cache;
	private Gdk.Pixbuf logo;
	
	public Popups(Prefs _prefs, Cache _cache, Gdk.Pixbuf _logo) {
		//libnotify init
		Notify.init(Config.APPNAME);
		
		prefs = _prefs;
		cache = _cache;
		logo = _logo;
	}
	
	public void start(ArrayList<Status> home, ArrayList<Status> mentions,
		ArrayList<Status> direct) {
		
		if(prefs.showFullNotify)
			full_notify(home, mentions, direct);
		else
			low_notify(home, mentions, direct);
	}
	
	private void show_popup(Status status) {
		Notification popup = new Notification(status.user_name,
			status.text, null, null);
		
		string av_path = cache.get_or_download(status.user_avatar, Cache.Method.ASYNC, false);
		if(av_path == status.user_avatar)
			popup.set_icon_from_pixbuf(logo);
		else {
			popup.set_icon_from_pixbuf(new Gdk.Pixbuf.from_file(av_path));
		}
		popup.set_timeout(100000); //doesn't working... hm
		popup.set_urgency(Notify.Urgency.NORMAL);
		popup.show();
	}
	
	private void show_short_popup(string text) {
		Notification popup = new Notification(_("Updates"),
			text, null, null);
		popup.set_icon_from_pixbuf(logo);
		popup.set_timeout(100000);
		popup.set_urgency(Notify.Urgency.NORMAL);
		popup.show();
	}
	
	/* one popup for each new status or DM */
	private void full_notify(ArrayList<Status> home, ArrayList<Status> mentions,
		ArrayList<Status> direct) {
		
		ArrayList<string> ids = new ArrayList<string>();
		
		if(prefs.showTimelineNotify) {
			foreach(Status status in home) {
				if(status.user_screen_name != prefs.login) {
					show_popup(status);
					ids.add(status.id);
				}
			}
		}
		
		if(prefs.showMentionsNotify) {
			foreach(Status status in mentions) {
				if(!(status.id in ids))
					show_popup(status);
			}
		}
		
		if(prefs.showDirectNotify) {
			foreach(Status status in direct) {
				show_popup(status);
			}
		}
		
	}
	
	/* one popup on all updates */
	private void low_notify(ArrayList<Status> home, ArrayList<Status> mentions,
		ArrayList<Status> direct) {
		
		string result = "";
		
		if(prefs.showTimelineNotify && home.size > 0)
			result += _("in the home timeline: %d\n").printf(home.size);
		
		if(prefs.showMentionsNotify && mentions.size > 0)
			result += _("in mentions: %d\n").printf(mentions.size);
		
		if(prefs.showDirectNotify && direct.size > 0)
			result += _("in direct messages: %d").printf(direct.size);
		
		if(result != "")
			show_short_popup(result);
	}
}
