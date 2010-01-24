namespace TimeUtils {
	
	public Time get_current_time() {
		var tval = TimeVal();
		tval.get_current_time();
		return Time.local((time_t)tval.tv_sec);
	}
	
	public int tz_delta(Time t) {
		string sdelta = t.format("%z");
		
		return sdelta.to_int() / 100;
	}
}
