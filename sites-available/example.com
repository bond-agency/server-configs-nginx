# www to non-www redirect -- duplicate content is BAD:
# https://github.com/h5bp/html5-boilerplate/blob/5370479476dceae7cc3ea105946536d6bc0ee468/.htaccess#L362
# Choose between www and non-www, listen on the *wrong* one and redirect to
# the right one -- http://wiki.nginx.org/Pitfalls#Server_Name

# Page caching
fastcgi_cache_path /srv/www/EXAMPLE.COM/cache levels=1:2 keys_zone=EXAMPLE.COM:100m inactive=60m;

server {
  listen [::]:80;
  listen 80;

  # listen on the www host
  server_name www.EXAMPLE.COM;

  # and redirect to the non-www host (declared below)
  return 301 http://EXAMPLE.COM$request_uri;
}

server {
  listen [::]:80;
  listen 80;

  # The host name to respond to
  server_name EXAMPLE.COM;

  # Path for static files
  root /srv/www/EXAMPLE.COM/public;

  # Require authentication to access the directory. Enable if needed.
  # If you are using this you must disable the global wordpress confs.
  #location / {
  # auth_basic "Login required";
  # auth_basic_user_file /srv/www/EXAMPLE.COM/htpasswd;
  # try_files $uri $uri/ /index.php?$args;
  #}

  # Custom log locations. Enable if needed.
  #error_log  /srv/www/EXAMPLE.COM/logs/error.log warn;
  #access_log /srv/www/EXAMPLE.COM/logs/access.log main;

  # Custom 404 page. Enable if needed.
  #error_page 404 /404.html;

  #########################################
  # Speed, Caching, Limiting              #
  #########################################

  # Pagespeed (on/off)
  pagespeed off;

  # Skip fastcgi caching (1/0)
  # 0 = cache is active, 1= cache is set off
  set $skip_cache 1;

  # Include page caching exclude configuration. Wether you cache
  # or not this should be included after your skip setting.
  include global/cache-exclude.conf;

  # Limit connections per IP (to this host).
  limit_conn conn_per_ip 32;

  #########################################
  # FastCGI cache configuration           #
  #########################################

  # Site level settings for fastcgi cache
  fastcgi_cache EXAMPLE.COM;
  fastcgi_cache_lock on;
  fastcgi_cache_lock_age 3s;
  fastcgi_cache_lock_timeout 3s;
  fastcgi_cache_use_stale updating error timeout invalid_header http_500 http_503;
  fastcgi_cache_background_update on;
  fastcgi_cache_revalidate on;
  fastcgi_cache_valid 200 301 302 404 1h;

  # Enable purge by appending /purge to the page URL
  location ~ /purge(/.*) {
    fastcgi_cache_purge EXAMPLE.COM "$scheme$request_method$host$1";
  }

  #########################################
  # PageSpeed configuration               #
  #########################################

  # Enable configuration level
  pagespeed RewriteLevel CoreFilters;

  # Enabled extra rules
  pagespeed EnableFilters collapse_whitespace,insert_dns_prefetch;

  # Needs to exist and be writable by nginx. Use tmpfs for best performance.
  pagespeed FileCachePath /var/ngx_pagespeed_cache/EXAMPLE.COM;

  # Needed for WPML directory test to pass
  pagespeed Disallow "*icl_validate_domain=1*";

  # Ensure requests for pagespeed optimized resources go to the pagespeed handler
  # and no extraneous headers get set.
  location ~ "\.pagespeed\.([a-z]\.)?[a-z]{2}\.[^.]{10}\.[^.]+" {
    add_header "" "";
  }
  location ~ "^/pagespeed_static/" { }
  location ~ "^/ngx_pagespeed_beacon$" { }

  #########################################
  # WordPress & PHP-FPM configuration     #
  #########################################

  # Include global restrictions
  include global/restrictions.conf;
  
  # Redirects for WP Yoast SEO sitemaps
  include global/yoast-wordpress-seo.conf;

  # Include the basic h5bp config set
  include h5bp/basic.conf;

  # Include global WordPress specific settings.
  include global/wordpress.conf;

  # Pass all .php files onto a php-fpm/php-fcgi server.
  location ~ [^/]\.php(/|$) {
  fastcgi_split_path_info ^(.+?\.php)(/.*)$;
    # This is a robust solution for path info security issue and works
    # with "cgi.fix_pathinfo = 1" in /etc/php.ini (default).
    if (!-f $document_root$fastcgi_script_name) {
      return 404;
    }

    include fastcgi.conf;
    fastcgi_param HTTP_PROXY ""; # https://httpoxy.org/#prevent
    fastcgi_index index.php;
    #fastcgi_intercept_errors on;
    fastcgi_pass 127.0.0.1:9000;

    fastcgi_cache_bypass $skip_cache;
    fastcgi_no_cache $skip_cache;

    # Limit requests to php files.
    limit_req zone=req_per_ip burst=20 nodelay;
  }
}
