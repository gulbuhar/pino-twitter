<div class="status">
	<div class="avatar" style="background-image:url('{{avatar}}');"></div>
	<div class="content_{{fresh}}" id="{{id}}">
		<div class="header">
			<a class="nick" href="nickto://{{screen_name}}">{{name}}</a>
			<span class="date">{{time}}</span>
		</div>
		<div class="{{rtl_class}}">
			{{content}}
		</div>
		<div class="footer">
			<span>&nbsp;</span><span class="footer-right"><a class="reply" title="reply to {{name}}" href="directreply://{{id}}=={{screen_name}}=={{name}}"><img src="{{direct_reply}}" /></a>&nbsp;&nbsp;<a class="reply" title="{{delete_text}}" href="deletedirect://{{id}}"><img src="{{delete}}" /></a></span>
		</div>
	</div>
</div>
