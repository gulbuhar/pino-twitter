public interface IRestUrls : Object {
	
	public abstract string home { get; }
	public abstract string status_update { get; }
	public abstract string destroy_status { get; }
	public abstract string destroy_direct { get; }
	public abstract string direct_new { get; }
	public abstract string mentions { get; }
	public abstract string direct_in { get; }
	public abstract string user { get; }
	public abstract string friendship { get; }
}
