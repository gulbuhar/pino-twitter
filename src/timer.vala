public class SmartTimer : Object
{
	private double interval;
	private double elapsed = 0;
	
	public signal void timeout();
	
	public SmartTimer(uint _interval)
	{
		interval = _interval;
		Timeout.add_seconds(60, callback);
	}
	
	public void set_interval(double _interval)
	{
		interval = _interval;
		elapsed = 0;
	}
	
	private bool callback()
	{
		elapsed += 60;
		if(elapsed >= interval)
		{
			elapsed = 0;
			timeout();
			warning("timeout!");
		}
		return true;
	}
}