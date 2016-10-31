#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad"
DB="zammad_production"
DB_USER="zammad"

# check which init system is used
if [ -n "$(which initctl)" ]; then
    INIT_CMD="initctl"
elif [ -n "$(which systemctl)" ]; then
    INIT_CMD="systemctl"
else
    function sysvinit () {
	service $2 $1
    }
    INIT_CMD="sysvinit"
fi

echo "# (Re)creating init scripts"
zammad scale web=1 websocket=1 worker=1

echo "# Stopping Zammad"
${INIT_CMD} stop zammad

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    # db migration
    echo "# database.yml exists. Updating db..."
    zammad run rake db:migrate
else
    # create new password
    DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c10)"

    if [ -n "$(which postgresql-setup)" ]; then
	echo "preparing postgresql server"
	postgresql-setup initdb
	
	echo "restarting postgresql server"
	${INIT_CMD} restart postgresql
    fi

    # create database
    echo "# database.yml not found. Creating new db..."
    su - postgres -c "createdb -E UTF8 ${DB}"

    # create postgres user
    echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql 

    # grant privileges
    echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

    # update configfile
    sed "s/.*password:.*/  password: ${DB_PASS}/" < ${ZAMMAD_DIR}/config/database.yml.pkgr > ${ZAMMAD_DIR}/config/database.yml

    # fill database
    zammad run rake db:migrate 
    zammad run rake db:seed
fi

echo "# Starting Zammad"
${INIT_CMD} start zammad

# nginx config
if [ -n "$(which nginx)" ]; then
    # copy nginx config
    # debian / ubuntu
    if [ -d /etc/nginx/sites-enabled ]; then
	NGINX_CONF="/etc/nginx/sites-enabled/zammad.conf"
	test -f /etc/nginx/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
	test -h ${NGINX_CONF} || ln -s /etc/nginx/sites-available/zammad.conf ${NGINX_CONF}
    # centos / sles
    elif [ -d /etc/nginx/conf.d ]; then
	NGINX_CONF="/etc/nginx/conf.d/zammad.conf"
	test -f ${NGINX_CONF} || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf ${NGINX_CONF}
    fi

    echo "# Restarting Nginx"
    ${INIT_CMD} restart nginx

    echo -e "\nAdd your FQDN to servername directive in ${NGINX_CONF} and restart nginx if you're not testing localy"
    echo -e "or open http://localhost in your browser to start using Zammad.\n"
else
    echo -e "\nOpen http://localhost:3000 in your browser to start using Zammad.\n"
fi
