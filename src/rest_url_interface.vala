/* rest_url_interface.vala
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
