namespace TimeUtils {
	
	public Time get_current_time() {
		var tval = TimeVal();
		tval.get_current_time();
		return Time.local((time_t)tval.tv_sec);
	}
	
	public int tz_delta(Time t) {
		int xdelta = 0;
 		string sdelta = t.format("%z");
 		
 		xdelta += sdelta.substring(1, 2).to_int()*3600;
		xdelta += sdelta.substring(3, 2).to_int()*60;
		
		if(sdelta[0]=='-')
			xdelta *= -1;
		
		return xdelta;
	}
	
	public Time str_to_time(string str) {
		var tmpTime = Time();
		tmpTime.strptime(str, "%a %b %d %T +0000 %Y");
		var tt = tmpTime.mktime();
		var tmp = Time.local(tt);
		int delta = tz_delta(tmp);
		int int_t = (int)tt + delta;
		
		return Time.local((time_t)int_t);
	}
}
