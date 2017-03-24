#!/bin/bash

if [ -z "$MYSQL_ROOT_PASS" ]; then
	sql_pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
fi

init_mysql() {
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
	
	service mysql start
}


init_web() {
if [ ! -e '/var/www/html/web.config' ]; then
	cp -R /usr/src/clonedeploy/${CLONEDEPLOY_PATCH}/web/. /usr/src/clonedeploy/web/
	cp -R /usr/src/clonedeploy/web/. /var/www/html
	mkdir /var/www/.mono
	chown -R www-data /var/www/.mono
	
	rand_key=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
	sed -i  "s/xx_marker1_xx/$sql_pass/" /var/www/html/web.config
	sed -i  "s/xx_marker2_xx/$rand_key/" /var/www/html/web.config
fi
}


	
init_smb() {
mkdir -p /cd_dp/images
mkdir -p /cd_dp/resources
if [ "$LOAD_SMB" = "true" ]; then
	(echo "$RW_SMB_PASS"; echo "$RW_SMB_PASS") | smbpasswd -as cd_share_rw
	(echo "$RO_SMB_PASS"; echo "$RO_SMB_PASS") | smbpasswd -as cd_share_ro
	service smbd start
fi
}

init_tftp() {
if [ ! -e '/tftpboot/DO_NOT_MODIFY.txt' ]; then
	cp -R /usr/src/clonedeploy/${CLONEDEPLOY_PATCH}/tftpboot/. /usr/src/clonedeploy/tftpboot/
	cp -R /usr/src/clonedeploy/tftpboot /
fi

if [ "$LOAD_TFTP" = "true" ]; then
		service tftpd-hpa start
fi
}


fix_permissions() {
chown -R www-data /tftpboot /cd_dp /var/www/html
chmod 1777 /tmp
chown -R www-data:cdsharewriters /cd_dp
chmod -R 2777 /cd_dp
ln -s ../../images /tftpboot/proxy/bios/images
ln -s ../../images /tftpboot/proxy/efi32/images
ln -s ../../images /tftpboot/proxy/efi64/images
ln -s ../../kernels /tftpboot/proxy/bios/kernels
ln -s ../../kernels /tftpboot/proxy/efi32/kernels
ln -s ../../kernels /tftpboot/proxy/efi64/kernels

}

init_mysql
init_web
init_smb
init_tftp
fix_permissions

exec "$@"

