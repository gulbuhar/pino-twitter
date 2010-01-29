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
