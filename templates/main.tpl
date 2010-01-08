<html>
<head>
<style type="text/css">
body{background-color: {{bg_color}}; color: {{fg_color}}; font-family: "DejaVu Sans"; font-size: 9pt;}
.nick{font-size: 10pt; margin: 0px; margin-bottom: 0px; font-weight: bold; color: {{fg_color}}; text-decoration: none;cursor: pointer;}
.content_me .nick{float: right;}
.status{width: 100%; margin-bottom: 10px; padding-top: 2px;}
.avatar, .avatar_me{width: 48px; height: 48px; float: left; {{rounded}} background-repeat: no-repeat; -webkit-background-size: 48px 48px;}
.avatar_me{float: right; rght: 0px;}
.content_old, .content_fresh, .content_me{padding: 5px; background-color: rgba(256, 256, 256, {{tweets_opacity}}); margin-top: -2px; {{rounded}} border-color: {{dr_color}}; border-width: 2px; border-style: solid; border-bottom-width: 2px; border-right-width: 2px; cursor:default; margin-left: 60px;}
.content_me{margin-left: 0px; margin-right: 60px;}
.content_fresh{background-color: rgba(203, 189, 175, 0.3);}
.date{float: right; font-size: 8pt; color: {{lt_color}};}
.content_me .date{float: none;}
.content_me .nick{cursor: default;}
a, a.tags{color: {{sl_color}};}
a.tags{text-decoration: none; font-weight: bold;}
.re_nick{color: {{fg_color}}; font-weight: bold; text-decoration: none;}
.reply, .delete, .by_who{text-decoration: none; text-align: right; font-size: 8pt; color: {{lt_color}};}
.delete{text-align: left;}
.by_who{display: inline; text-align: left;}
.re{background-color: {{sl_color}}; color: {{lg_color}}; -webkit-border-radius: 3px; font-weight: bold; padding-left: 3px; padding-right: 3px;}
.header {margin-bottom: 4px;}
.footer {margin-top: 4px;}
</style>
</head>
<body>
{{main_content}}
</body>
</html>
