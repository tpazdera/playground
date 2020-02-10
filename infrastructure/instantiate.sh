#!/bin/bash

WP_HOME=/var/www/html/about-us
REWRITE_BASE=/about-us

. /tmp/create-wp-config

#
#  Move Wordpress to Wordpress Home
#

if [ ! -d $WP_HOME ]
then 
  mkdir $WP_HOME
fi

mv /tmp/wordpress/* $WP_HOME
mv $WP_HOME/wp-content $WP_HOME/wp-contentORIG

if [ ! -d /var/www/html/NFS-wp-content/WP_CONTENT ]
then
  cp -nr $WP_HOME/wp-contentORIG /var/www/html/NFS-wp-content/WP_CONTENT
fi

ln -s /var/www/html/NFS-wp-content/WP_CONTENT $WP_HOME/wp-content
touch /var/www/html/index.html

chown -R apache:apache /var/www/html/*
chown -h apache:apache $WP_HOME/wp-content


#
# wp-config configuration
#

tr -d '\015' <$WP_HOME/wp-config-sample.php >$WP_HOME/wp-config.php

sed -i "s/'database_name_here'/'$DBName'/g" $WP_HOME/wp-config.php
sed -i "s/'username_here'/'$DBUsername'/g"  $WP_HOME/wp-config.php
sed -i "s/'password_here'/'$DBPassword'/g"  $WP_HOME/wp-config.php
sed -i "s/'localhost'/'$DBEndpoint'/g"      $WP_HOME/wp-config.php

sed -i -e "/^define( 'NONCE_SALT',       'put your unique phrase here' );/ a\\\ndefine('WP_SITEURL', 'https://' . \$_SERVER['HTTP_HOST'] . \'$REWRITE_BASE\');\ndefine('WP_HOME', 'https://' . \$_SERVER['HTTP_HOST'] . \'$REWRITE_BASE\');" \
       -e "/\/\*\* Sets up WordPress vars and included files. \*\// i\\/\/ Prevent redirection loop\n\/\/ See https:\/\/codex.wordpress.org\/Administration_Over_SSL#Using_a_Reverse_Proxy\ndefine('FORCE_SSL_ADMIN', true);\n\/\/if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)\n       \$_SERVER['HTTPS']='on';\n" \
$WP_HOME/wp-config.php

chown apache:apache $WP_HOME/wp-config.php

#
# Configure Apache httpd.conf
#

sed -i -e 's/^ServerAdmin root@localhost$/ServerAdmin cbadmin@caringbridge.org/' \
       -e 's/^#ServerName www.example.com:80$/ServerName localhost:80/' \
       -e '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/^    AllowOverride None$/    AllowOverride All/' \
       -e 's/^    DirectoryIndex index.html$/    DirectoryIndex index.html index.php/' \
/etc/httpd/conf/httpd.conf


cat <<APACHE_EOF >> /etc/httpd/conf/httpd.conf

# Reduce Server HTTP Header to the minimum product (Apache) rather than showing detailed version information of the server and operating system
ServerTokens Prod

# Remove the footer from error pages, which details the version numbers:
ServerSignature Off

# Hide X-Powered-By and Server headers, sent by downstream application servers:
# Note you need both below as the "always" one doesn't work with Jboss for some reason
Header always unset "X-Powered-By"
Header unset "X-Powered-By"
APACHE_EOF


#
# Add .htaccess
#

cat <<'HTACCESS_EOF' > $WP_HOME/.htaccess
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase xxREWRITE_BASExx
    RewriteCond %{HTTPS} =on
    RewriteRule .* - [E=W3TC_SSL:_ssl]
    RewriteCond %{SERVER_PORT} =443
    RewriteRule .* - [E=W3TC_SSL:_ssl]
    RewriteCond %{HTTP:X-Forwarded-Proto} =https [NC]
    RewriteRule .* - [E=W3TC_SSL:_ssl]
    RewriteCond %{HTTP:Accept-Encoding} gzip
    RewriteRule .* - [E=W3TC_ENC:_gzip]
    RewriteCond %{HTTP_COOKIE} w3tc_preview [NC]
    RewriteRule .* - [E=W3TC_PREVIEW:_preview]
    RewriteCond %{REQUEST_METHOD} !=POST
    RewriteCond %{QUERY_STRING} =""
    RewriteCond %{HTTP_COOKIE} !(comment_author|wp\-postpass|w3tc_logged_out|wordpress_logged_in|wptouch_switch_toggle) [NC]
    RewriteCond "%{DOCUMENT_ROOT}/wp-content/cache/page_enhanced/%{HTTP_HOST}/%{REQUEST_URI}/_index%{ENV:W3TC_SSL}%{ENV:W3TC_PREVIEW}.html%{ENV:W3TC_ENC}" -f
    RewriteRule .* "/wp-content/cache/page_enhanced/%{HTTP_HOST}/%{REQUEST_URI}/_index%{ENV:W3TC_SSL}%{ENV:W3TC_PREVIEW}.html%{ENV:W3TC_ENC}" [L]
</IfModule>

# Remove direct access to a directory, such as /wp-content/uploads
#Options -Indexes

# BEGIN WordPress
# The directives (lines) between `BEGIN WordPress` and `END WordPress` are
# dynamically generated, and should only be modified via WordPress filters.
# Any changes to the directives between these markers will be overwritten.
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase xxREWRITE_BASExx/
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . xxREWRITE_BASExx/index.php [L]
</IfModule>

# END WordPress
HTACCESS_EOF

sed -i "s#xxREWRITE_BASExx#$REWRITE_BASE#g" $WP_HOME/.htaccess
