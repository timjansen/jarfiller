#NameVirtualHost *
<VirtualHost *>
	ServerName jarfiller.com
	ServerAlias jarfiller.com jarfiller.org jarfiller.net www.jarfiller.com www.jarfiller.org www.jarfiller.net 
	ServerAdmin tim@tjansen.de
	
	DocumentRoot /var/www/jarfiller.com/html/
	<Directory />
		Options FollowSymLinks
		AllowOverride All
		Order allow,deny
		allow from all
	</Directory>
	<Directory /var/www/>
		Options FollowSymLinks MultiViews
		AllowOverride all
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /var/www/jarfiller.com/cgi-bin/
	<Directory "/var/www/jarfiller.com/cgi-bin">
		AllowOverride None
		Options ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog /var/log/apache2/error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog /var/log/apache2/jarfiller-access.log combined
	ServerSignature On


	# Enable chrome
	BrowserMatch chromeframe gcf
        Header append X-UA-Compatible "chrome=1" env=gcf

    # Compress XHTML
    AddOutputFilterByType DEFLATE AddOutputFilterByType DEFLATE application/xhtml+xml image/svg+xml application/x-javascript text/css


	RewriteEngine On
	
	# Redirect all domains to jarfiller.com
	RewriteCond %{HTTP_HOST} ^(www\.jarfiller\.(com|net|org)|jarfiller\.org|jarfiller\.net)$
	RewriteRule /(.*) http://jarfiller.com/$1 [R=301,L]

	# Redirect IE without Chrome Frame and cookie to no_x.html
	RewriteCond %{REQUEST_URI} \.xhtml$ [OR]
	RewriteCond %{REQUEST_URI} /$
	RewriteCond %{HTTP_USER_AGENT} MSIE
	RewriteCond %{HTTP_USER_AGENT} !Trident/[5-9]
	RewriteCond %{HTTP_USER_AGENT} !chromeframe
	RewriteCond %{HTTP_COOKIE} !xhtmlcookie=1
	RewriteRule .* /errors/no_x.html [L]

	# Set XHTML cookie for /setxhtmlcookie.do and send back to start
	RewriteRule ^/setxhtmlcookie.do / [CO=xhtmlcookie:1:jarfiller.com:260000,R,L] 


</VirtualHost>
