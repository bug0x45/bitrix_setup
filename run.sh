#!/bin/sh
#
# metadata_begin
# recipe: Bitrix
# tags: debian12
# revision: 1
# description_ru: Установка Bitrix CMS
# description_en: Bitrix CMS installing
# metadata_end

cat > /root/run.sh <<\END

set -x
LOG_PIPE=/tmp/log.pipe
mkfifo ${LOG_PIPE}
LOG_FILE=/root/recipe.log
touch ${LOG_FILE}
chmod 600 ${LOG_FILE}
tee < ${LOG_PIPE} ${LOG_FILE} &
exec > ${LOG_PIPE}
exec 2> ${LOG_PIPE}

dbconn() {
	cat <<-EOF
		<?
		define("DBPersistent", false);
		\$DBType = "mysql";
		\$DBHost = "localhost";
		\$DBLogin = 'bitrix';
		\$DBPassword = '${DBPASS}';
		\$DBName = "bitrix";
		\$DBDebug = false;
		\$DBDebugToFile = false;
		define("DELAY_DB_CONNECT", true);
		define("CACHED_b_file", 3600);
		define("CACHED_b_file_bucket_size", 10);
		define("CACHED_b_lang", 3600);
		define("CACHED_b_option", 3600);
		define("CACHED_b_lang_domain", 3600);
		define("CACHED_b_site_template", 3600);
		define("CACHED_b_event", 3600);
		define("CACHED_b_agent", 3660);
		define("CACHED_menu", 3600);
		define("BX_FILE_PERMISSIONS", 0644);
		define("BX_DIR_PERMISSIONS", 0755);
		@umask(~(BX_FILE_PERMISSIONS|BX_DIR_PERMISSIONS)&0777);
		define("MYSQL_TABLE_TYPE", "INNODB");
		define("SHORT_INSTALL", true);
		define("VM_INSTALL", true);
		define("BX_UTF", true);
		define("BX_CRONTAB_SUPPORT", false);
		define("BX_COMPRESSION_DISABLED", true);
		define("BX_DISABLE_INDEX_PAGE", true);
		define("BX_USE_MYSQLI", true);
		?>
	EOF
}

settings() {
	cat <<-EOF
		<?php
		return array (
		  'utf_mode' =>
		  array (
		    'value' => true,
		    'readonly' => true,
		  ),
		  'cache_flags' =>
		  array (
		    'value' =>
		    array (
		      'config_options' => 3600,
		      'site_domain' => 3600,
		    ),
		    'readonly' => false,
		  ),
		  'cookies' =>
		  array (
		    'value' =>
		    array (
		      'secure' => false,
		      'http_only' => true,
		    ),
		    'readonly' => false,
		  ),
		  'exception_handling' =>
		  array (
		    'value' =>
		    array (
		      'debug' => false,
		      'handled_errors_types' => 4437,
		      'exception_errors_types' => 4437,
		      'ignore_silence' => false,
		      'assertion_throws_exception' => true,
		      'assertion_error_type' => 256,
		      'log' => array (
			  'settings' =>
			  array (
			    'file' => '/var/log/php/exceptions.log',
			    'log_size' => 1000000,
			),
		      ),
		    ),
		    'readonly' => false,
		  ),
		  'crypto' =>
		  array (
		    'value' =>
		    array (
			'crypto_key' => "${PUSH_KEY}",
		    ),
		    'readonly' => true,
		  ),
		  'connections' =>
		  array (
		    'value' =>
		    array (
		      'default' =>
		      array (
			'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
			'host' => 'localhost',
			'database' => 'bitrix',
			'login'    => 'bitrix',
			'password' => '${DBPASS}',
			'options' => 2,
		      ),
		    ),
		    'readonly' => true,
		  ),
		'pull_s1' => 'BEGIN GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
		  'pull' => Array(
		    'value' =>  array(
			'path_to_listener' => "http://#DOMAIN#/bitrix/sub/",
			'path_to_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
			'path_to_modern_listener' => "http://#DOMAIN#/bitrix/sub/",
			'path_to_modern_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
			'path_to_mobile_listener' => "http://#DOMAIN#:8893/bitrix/sub/",
			'path_to_mobile_listener_secure' => "https://#DOMAIN#:8894/bitrix/sub/",
			'path_to_websocket' => "ws://#DOMAIN#/bitrix/subws/",
			'path_to_websocket_secure' => "wss://#DOMAIN#/bitrix/subws/",
			'path_to_publish' => 'http://127.0.0.1:8895/bitrix/pub/',
			'nginx_version' => '4',
			'nginx_command_per_hit' => '100',
			'nginx' => 'Y',
			'nginx_headers' => 'N',
			'push' => 'Y',
			'websocket' => 'Y',
			'signature_key' => '${PUSH_KEY}',
			'signature_algo' => 'sha1',
			'guest' => 'N',
		    ),
		  ),
		'pull_e1' => 'END GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
		);
	EOF
}

installPkg(){
	type=$(lsb_release -is|tr '[A-Z]' '[a-z]')
	release=$(lsb_release -sc|tr '[A-Z]' '[a-z]')

	apt update
	apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 unzip rsync nftables pwgen make build-essential wget curl
	curl -s -o /etc/apt/trusted.gpg.d/sury.gpg https://mirror.hoztnode.net/mirrors/deb.sury.org/apt.gpg
	echo "deb https://mirror.hoztnode.net/mirrors/deb.sury.org/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
	wget -qO- 'https://repo.mysql.com/RPM-GPG-KEY-mysql-2023' |gpg --dearmor -o /etc/apt/trusted.gpg.d/mysql-keyring.gpg
	echo "deb [signed-by=/etc/apt/trusted.gpg.d/mysql-keyring.gpg] http://repo.mysql.com/apt/$type $release mysql-tools mysql-8.0" > /etc/apt/sources.list.d/mysql.list
  apt update
	export DEBIAN_FRONTEND="noninteractive"
	debconf-set-selections <<< 'exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP'
  apt install -y  php8.3 php8.3-cli \
                  php8.3-common php8.3-gd php8.3-ldap \
                  php8.3-mbstring php8.3-mysql \
                  php8.3-opcache \
                  php-pear php8.3-apcu php-geoip \
                  php8.3-mcrypt php8.3-memcache \
                  php8.3-zip php8.3-pspell php8.3-xml \
                  libapache2-mod-php8.3 \
                  apache2 nginx mysql-community-server mysql-community-client \
                  nodejs npm redis \
                  exim4 exim4-config
}

dplApache(){
		mkdir /etc/systemd/system/apache2.service.d
		cat <<EOF >> /etc/systemd/system/apache2.service.d/privtmp.conf
[Service]
PrivateTmp=false
Restart=always
RestartSec=1s
EOF
		systemctl daemon-reload
	  ln -sf /etc/php/8.3/mods-available/zbx-bitrix.ini  /etc/php/8.3/apache2/conf.d/99-bitrix.ini
    ln -sf /etc/php/8.3/mods-available/zbx-bitrix.ini  /etc/php/8.3/cli/conf.d/99-bitrix.ini
		sed -i 's|date.timezone = UTC|date.timezone = Europe/Moscow|' /etc/php/8.3/apache2/conf.d/99-bitrix.ini
    a2dismod --force autoindex
    a2enmod rewrite
    a2enmod php8.3
		systemctl stop apache2
		sleep 2
		systemctl enable --now apache2
		systemctl start apache2
}

dplNginx(){
	echo "127.0.0.1 push httpd" >> /etc/hosts
	rm /etc/nginx/sites-enabled/default
	ln -s /etc/nginx/sites-available/rtc.conf /etc/nginx/sites-enabled/rtc.conf
	ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
	systemctl stop nginx
	systemctl enable --now nginx
	systemctl start nginx
}

dplRedis(){
		echo -e "pidfile /run/redis/redis-server.pid\ndir /var/lib/redis" >> /etc/redis/redis.conf
		echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
		sysctl vm.overcommit_memory=1
	  usermod -g www-data redis
    chown root:www-data /etc/redis/ /var/log/redis/
    [[ ! -d /etc/systemd/system/redis.service.d ]] && mkdir /etc/systemd/system/redis.service.d
    echo -e '[Service]\nGroup=www-data\nPIDFile=/run/redis/redis-server.pid' > /etc/systemd/system/redis.service.d/custom.conf
    systemctl daemon-reload
    systemctl stop redis
    systemctl enable --now redis || systemctl enable --now redis-server
    systemctl start redis
}

dplPush(){
	cd /opt
	wget -q https://repo.bitrix.info/vm/push-server-0.3.0.tgz
	npm install --production ./push-server-0.3.0.tgz
	rm ./push-server-0.3.0.tgz
	ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server

	cd /opt/node_modules/push-server
	cp etc/init.d/push-server-multi /usr/local/bin/push-server-multi
	mkdir /etc/sysconfig
	cp etc/sysconfig/push-server-multi  /etc/sysconfig/push-server-multi
	cp etc/push-server/push-server.service  /etc/systemd/system/
	ln -sf /opt/node_modules/push-server /opt/push-server
	useradd -g www-data bitrix

	cat <<EOF >> /etc/sysconfig/push-server-multi
GROUP=www-data
SECURITY_KEY="${PUSH_KEY}"
RUN_DIR=/tmp/push-server
REDIS_SOCK=/var/run/redis/redis.sock
WS_HOST=127.0.0.1
EOF
	/usr/local/bin/push-server-multi configs pub
	/usr/local/bin/push-server-multi configs sub
	echo 'd /tmp/push-server 0770 bitrix www-data -' > /etc/tmpfiles.d/push-server.conf
	systemd-tmpfiles --remove --create
	[[ ! -d /var/log/push-server ]] && mkdir /var/log/push-server
	chown bitrix:www-data /var/log/push-server

	sed -i 's|User=.*|User=bitrix|;s|Group=.*|Group=www-data|;s|ExecStart=.*|ExecStart=/usr/local/bin/push-server-multi systemd_start|;s|ExecStop=.*|ExecStop=/usr/local/bin/push-server-multi stop|' /etc/systemd/system/push-server.service
	systemctl daemon-reload
	systemctl stop push-server
	systemctl --now enable push-server
	systemctl start push-server
}

dplMYSQL() {
	echo 'innodb_strict_mode=off' >> /etc/mysql/my-bx.d/zbx-custom.cnf
	sed -i 's|/etc/mysql/mariadb.conf.d/|/etc/mysql/mysql.conf.d/|' /etc/mysql/my.cnf
	mysql -e "create database bitrix;create user bitrix@localhost;grant all on bitrix.* to bitrix@localhost;ALTER USER bitrix@localhost IDENTIFIED BY '${DBPASS}'"
	systemctl stop mysql
	systemctl --now enable mysql
	systemctl start mysql
}

nfTabl(){
	cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
	chain input {
		type filter hook input priority 0; policy drop;
		iif "lo" accept comment "Accept any localhost traffic"
		ct state invalid drop comment "Drop invalid connections"
		ip protocol icmp limit rate 4/second accept
		ip6 nexthdr ipv6-icmp limit rate 4/second accept
		ct state { established, related } accept comment "Accept traffic originated from us"
		tcp dport 22 accept comment "ssh"
		tcp dport { 80, 443 } accept comment "web"
	}
	chain forward {
		type filter hook forward priority 0;
	}
	chain output {
		type filter hook output priority 0;
	}
}
EOF
	systemctl restart nftables
	systemctl enable nftables.service
}

deployConfig() {

	wget -q 'https://dev.1c-bitrix.ru/docs/chm_files/debian.zip'
  unzip debian.zip && rm debian.zip
  rsync -a --exclude=php.d ./debian/ /etc/
  rsync -a ./debian/php.d/ /etc/php/8.3/mods-available/
  rsync -a ./debian/php.d/ /etc/php/7.4/mods-available/
	mkdir -p /var/www/html/bx-site

	nfTabl
	dplApache
	dplNginx
	dplRedis
	dplPush
	dplMYSQL

  systemctl --now enable mariadb
}

deployInstaller() {
	cd /var/www/html/bx-site
	wget -q 'https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php'
	wget -q 'https://www.1c-bitrix.ru/download/scripts/restore.php'
	mkdir -p bitrix/php_interface
	dbconn > bitrix/php_interface/dbconn.php
	settings > bitrix/.settings.php
	chown -R www-data:www-data /var/www/html/bx-site
}

installPkg

PUSH_KEY=$(pwgen 24 1)
DBPASS=$(pwgen 24 1)

deployConfig
deployInstaller

ip=$(wget -qO- "https://ipinfo.io/ip")
curl -s "http://${ip}/bitrixsetup.php"|grep 'bitrixsetup' >/dev/null || exit 1

END

bash /root/run.sh
