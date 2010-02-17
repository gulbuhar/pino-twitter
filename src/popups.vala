/* popup.vala
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
	
	public void start(ArrayList<Status>? home, ArrayList<Status>? mentions,
		ArrayList<Status>? direct) {
		if(home == null)
			return;
		
		if(home.size > 3 || mentions.size > 3 || direct.size > 3)
			low_notify(home, mentions, direct);
		else
			full_notify(home, mentions, direct);
	}
	
	private void show_popup(Status status, bool direct = false) {
		string head = status.user_name;
		if(direct)
			head = "%s %s %s".printf(_("Direct message"), _("from"), head);
		
		Notification popup = new Notification(head, status.text, null, null);
		
		string av_path = cache.get_or_download(status.user_avatar,
			Cache.Method.ASYNC, false);
		if(av_path == status.user_avatar)
			popup.set_icon_from_pixbuf(logo);
		else {
			popup.set_icon_from_pixbuf(new Gdk.Pixbuf.from_file(av_path));
		}
		popup.set_timeout(5000); //doesn't working... hm
		popup.set_urgency(Notify.Urgency.NORMAL);
		popup.show();
	}
	
	private void show_short_popup(string text) {
		Notification popup = new Notification(_("Updates"),
			text, null, null);
		popup.set_icon_from_pixbuf(logo);
		popup.set_timeout(5000);
		popup.set_urgency(Notify.Urgency.NORMAL);
		popup.show();
	}
	
	/* one popup for each new status or DM */
	private void full_notify(ArrayList<Status> home, ArrayList<Status> mentions,
		ArrayList<Status> direct) {
		
		ArrayList<string> ids = new ArrayList<string>();
		
		if(prefs.showTimelineNotify) {
			for(int i = home.size -1; i > -1; i--) {
				var status = home.get(i);
				if(status.user_screen_name != prefs.login) {
					show_popup(status);
					ids.add(status.id);
				}
			}
		}
		
		if(prefs.showMentionsNotify) {
			for(int i = mentions.size -1; i > -1; i--) {
				var status = mentions.get(i);
				if(!(status.id in ids))
					show_popup(status);
			}
		}
		
		if(prefs.showDirectNotify) {
			for(int i = direct.size -1; i > -1; i--) {
				var status = direct.get(i);
				show_popup(status, true);
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
