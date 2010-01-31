/* twitter_url.vala
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

public class TwitterUrls : Object, IRestUrls {
	
	public string home {
		get { return "http://api.twitter.com/1/statuses/home_timeline.xml"; }
	}
	
	public string status_update {
		get { return "http://twitter.com/statuses/update.xml"; }
	}
	
	public string destroy_status {
		get { return "http://twitter.com/statuses/destroy/%s.xml"; }
	}
	
	public string destroy_direct {
		get { return "http://twitter.com/direct_messages/destroy/%s.xml"; }
	}
	
	public string direct_new {
		get { return "http://twitter.com/direct_messages/new.xml"; }
	}
	
	public string mentions {
		get { return "http://twitter.com/statuses/mentions.xml"; }
	}
	
	public string direct_in {
		get { return "http://twitter.com/direct_messages.xml"; }
	}
		
	public string user {
		get { return "http://twitter.com/users/show/%s.xml"; }
	}
	
	public string friendship {
		get { return "http://twitter.com/friendships/show.xml"; }
	}
}
