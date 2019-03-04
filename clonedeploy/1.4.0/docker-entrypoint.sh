#!/bin/bash

init_mysql() {
	if [ ! -f /opt/clonedeploy/db_init_complete ]; then
		mkdir -p /var/lib/mysql /var/run/mysqld 
		chown -R mysql:mysql /var/lib/mysql /var/run/mysqld 
		chmod 777 /var/run/mysqld
		sed 's/^log_error/# log_error/' -i /etc/mysql/my.cnf
		sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/mysql.conf.d/mysqld.cnf 
		cat > /etc/mysql/conf.d/docker.cnf <<EOF
[mysqld]
skip-host-cache
skip-name-resolve
EOF
		touch /opt/clonedeploy/db_init_complete
	fi

	if [ ! -d /var/lib/mysql/clonedeploy ]; then
		echo 'Initializing database'
		mysqld --initialize-insecure
		echo 'Database initialized'
		
		mysqld --skip-networking --socket=/var/run/mysqld/mysqld.sock &
		pid="$!"

		mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock)

		for i in {30..0}; do
			if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
				break
			fi
			echo 'MySQL init process in progress...'
			sleep 1
		done
		if [ "$i" = 0 ]; then
			echo >&2 'MySQL init process failed.'
			exit 1
		fi

		/usr/bin/mysqladmin -u root create clonedeploy
		/usr/bin/mysqladmin -u root password ${sql_pass}
		/usr/bin/mysql -u root --password=${sql_pass} clonedeploy < /usr/src/clonedeploy/cd.sql
		/usr/bin/mysql -u root --password=${sql_pass} -e  "GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' identified by '${sql_pass}';flush privileges;"
		/usr/bin/mysqladmin -u root --password=${sql_pass} shutdown
	fi
	
	#sometimes this fails for some reason I don't know.  Try it twice.
	service mysql start
	service mysql start

}


init_web() {
	mkdir /var/www/.mono
	mkdir /etc/mono/registry
	sysctl fs.inotify.max_user_instances=1024
	if [ ! -f /var/www/html/clonedeploy/application/Web.config ]; then
		rm /var/www/html/index.html
		mkdir /var/www/html/clonedeploy 
		cp -r /usr/src/clonedeploy/frontend /var/www/html/clonedeploy
		cp -r /usr/src/clonedeploy/application /var/www/html/clonedeploy
		
		rand_key=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
		sed -i  "s/xx_marker1_xx/$sql_pass/" /var/www/html/clonedeploy/application/Web.config
		sed -i  "s/xx_marker2_xx/$rand_key/" /var/www/html/clonedeploy/application/Web.config

	else
		current_version=$(cat /var/www/html/clonedeploy/application/version)
		if [ "$current_version" != "$CLONEDEPLOY_VERSION" ]; then
			mv /usr/src/clonedeploy/frontend/Web.config /usr/src/clonedeploy/frontend/Web.config.ignore
			mv /usr/src/clonedeploy/application/Web.config /usr/src/clonedeploy/application/Web.config.ignore
			cp -r /usr/src/clonedeploy/frontend /var/www/html/clonedeploy
			cp -r /usr/src/clonedeploy/application /var/www/html/clonedeploy
		fi
	fi
	
}

init_smb() {	
if [ "$LOAD_SMB" = "true" ]; then
	mkdir -p /cd_dp/images
	mkdir /cd_dp/resources
	(echo "$RW_SMB_PASS"; echo "$RW_SMB_PASS") | smbpasswd -as cd_share_rw
	(echo "$RO_SMB_PASS"; echo "$RO_SMB_PASS") | smbpasswd -as cd_share_ro
	service smbd start
fi
}

init_tftp() {
if [ "$LOAD_TFTP" = "true" ]; then
	cp -R /usr/src/clonedeploy/tftpboot /
	ln -s ../../images /tftpboot/proxy/bios/images
	ln -s ../../images /tftpboot/proxy/efi32/images
	ln -s ../../images /tftpboot/proxy/efi64/images
	ln -s ../../kernels /tftpboot/proxy/bios/kernels
	ln -s ../../kernels /tftpboot/proxy/efi32/kernels
	ln -s ../../kernels /tftpboot/proxy/efi64/kernels
	service tftpd-hpa start
fi
}


fix_permissions() {
chown -R www-data:www-data /tftpboot /var/www/html/clonedeploy /var/www/.mono /etc/mono/registry
chmod 1777 /tmp
chown -R www-data:cdsharewriters /cd_dp
chmod -R 2777 /cd_dp

}

if [ -z "$MYSQL_ROOT_PASS" ]; then
	sql_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
else
	sql_pass=${MYSQL_ROOT_PASS}
fi

init_mysql
init_web
init_smb
init_tftp
fix_permissions

exec "$@"

