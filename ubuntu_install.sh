# Exit script immediately if any command exits with a non-zero status
set -e

CURRENT_DIR=$(pwd)

#functions

# Function to wait for the apt lock to be released (Ubuntu specific)
wait_for_apt_lock() {
    while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
        echo "Waiting for other apt processes to finish..."
        sleep 5
    done
}



sudo systemctl stop unattended-upgrades.service || true

wait_for_apt_lock



# Set Git environment variables to prevent username/password prompts
export GIT_TERMINAL_PROMPT=0

#defining variables
have_domains=''
machine_ip=$(hostname -I | cut -d' ' -f1)
backend_domain=''
frontend_domain=''
enable_ssl=''
PROTOCOL='http'
setup_mysql=''

backend_ssl_certificate_path=''
backend_ssl_certificate_key_path=''
frontend_ssl_certificate_path=''
frontend_ssl_certificate_key_path=''








ask_for_prompt(){
    #prompt user if he has domain to run qcomm on it or not
    read -p "Do you have domains to run qcomm on it? (y/n): " have_domains

    if [ "$have_domains" == "y" ]; then
        # Prompt user for domain name for backend
        read -p "Enter the domain for backend (e.g., example.com): " backend_domain

        # Prompt user for domain name for frontend
        read -p "Enter the domain for frontend (e.g., example.com): " frontend_domain

        # Prompt user if SSL should be enabled
        read -p "Do you want to enable SSL? (y/n): " enable_ssl

        if [ "$enable_ssl" == "y" ]; then
            # Prompt user for SSL certificate path for backend
            read -p "Enter the SSL certificate path for backend: " backend_ssl_certificate_path

            # Prompt user for SSL certificate key path for backend
            read -p "Enter the SSL certificate key path for backend: " backend_ssl_certificate_key_path

            # Prompt user for SSL certificate path for frontend
            read -p "Enter the SSL certificate path for frontend: " frontend_ssl_certificate_path

            # Prompt user for SSL certificate key path for frontend
            read -p "Enter the SSL certificate key path for frontend: " frontend_ssl_certificate_key_path

            PROTOCOL='https'

        fi

    
    else
        echo "Qcomm will be running on http://${machine_ip}/"
        backend_domain_name="${machine_ip}:8000"
    fi

    read -p "Do you want to set up a MySQL database? (y/n): " setup_mysql
}

install_essentials() {
    sudo apt clean
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev unzip
    sudo apt install -y libmysqlclient-dev libgl1-mesa-glx libgl1-mesa-dri

}

unzipping_folders() {
    sudo apt install -y unzip
    unzip Qcomm_Signage.zip -d ${CURRENT_DIR}
    mkdir -p ${CURRENT_DIR}/Qcomm_Frontend
    mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/Qcomm_Frontend
    cd ${CURRENT_DIR}/Qcomm_Frontend
    unzip dist.zip
    cd ${CURRENT_DIR}
    for file in ${CURRENT_DIR}/Qcomm_Frontend/main*; do
        sed -i 's|https://domain.com|'${PROTOCOL}://${backend_domain_name}'|g' "$file"
    done
}


# Function to install Python 3.7.14
install_python() {
    cd /usr/src
    sudo wget https://www.python.org/ftp/python/3.7.14/Python-3.7.14.tgz
    sudo tar xzf Python-3.7.14.tgz
    cd Python-3.7.14
    sudo ./configure --enable-optimizations
    sudo make altinstall
    python3.7 --version
    python3.7 -m pip --version
}

install_nginx() {
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
}

setup_virtualenv() {
    cd ${CURRENT_DIR}/Qcomm_Signage
    sudo pip3.7 install virtualenv
    python3.7 -m virtualenv env
    source env/bin/activate
    mkdir logs
    pip3.7 install drf-api-logger
    pip3.7 install pandas
    pip3.7 install gunicorn
    gunicorn --version
}


installation_libraries(){
    cd ${CURRENT_DIR}/Qcomm_Signage
    pip3.7 install -r requirements.txt
        
}

install_mysql(){
    sudo apt install -y mysql-server
    sudo systemctl start mysql.service
}

setup_mysql() {
    if [[ "$setup_mysql" == "y" ]]; then
        sudo mysql <<EOF
USE mysql;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
FLUSH PRIVILEGES;
CREATE DATABASE alertsdb;
CREATE USER 'django'@'localhost' IDENTIFIED BY '!Q2w3e4r5t';
GRANT ALL PRIVILEGES ON *.* TO 'django'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
EOF
        echo "max_connections = 2000" | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf
        cat <<EOF | tee ${CURRENT_DIR}/Qcomm_Signage/alerts/mysql_config.json >/dev/null
{
    "NAME": "alertsdb",
    "USER": "django",
    "PASSWORD": "!Q2w3e4r5t",
    "HOST": "127.0.0.1",
    "PORT": "3306"
}
EOF
    else
        # If MySQL setup is not needed, prompt user for database details
        read -p "Enter the MySQL host: " mysql_host
        read -p "Enter the MySQL port: " mysql_port
        read -p "Enter the MySQL username: " mysql_username
        read -sp "Enter the MySQL password: " mysql_password
        echo ""
        read -p "Enter the MySQL database name: " mysql_database

        # Create a configuration file with MySQL details in JSON format
        cat <<EOF | tee ${CURRENT_DIR}/Qcomm_Signage/alerts/mysql_config.json >/dev/null
{
    "NAME": "$mysql_database",
    "USER": "$mysql_username",
    "PASSWORD": "$mysql_password",
    "HOST": "$mysql_host",
    "PORT": "$mysql_port"
}
EOF
fi

    # Make migrations and migrate Django models
    python3.7 manage.py makemigrations api
    python3.7 manage.py migrate
}



create_env_file() {
    cat <<EOF | sudo tee ${CURRENT_DIR}/Qcomm_Signage/alerts/.env >/dev/null
EMAIL_PASSWORD='Q@1~3eT51427'
ILAIT_EMAIL_PASSWORD="C\$M=3XHS"
FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDdUuDdDXy9b7Ho\nHz3L3tgYS62ikgnR9gHOZajmAdUse3X/JS2h6iSiZkWoDYnQJnKdnKf8WRwUdmwS\nIDJE6sdr4XOXZB8qGcMGcPQ+4PzHtiOaAIMESN/26afo2uu+FLnzsfFBQz4S/qIC\nuHpJMNhCNmbA39xA+jZDmYoRGuq7vuDA8Qg+JSt0zpkv6gZWIVkeuOyjJY6GBCqh\nLLRkbpkIGtOxcBiOvWSGXixjnJm7jqDmbmm+SroUvFn1eZi/LzOc75fKn4vlXnPW\nm+6hFydD3z/F/ogyG26sXXNZdzKRgDwqgUnCIuWyp2HIsLvaN4nSskqAMj4pWNJ+\nfFlnaCCzAgMBAAECggEAaTdhVzV2O8jB1wwjIKyMJuCzZznuGTbOnQSPSulMIp1+\n9xEBpJvfVqUwMDhfb+kXS/6RjdH/G2tA7U0JGOJUc+D2Rt5+QlGE+abxNoNXKMpa\nGnhr0LmkX4mtHXIV6IOJ82SAwPnqpLUQ6CIzYGAsLy4Vo1PJLcrFyVVQ4djeBupQ\nrjTGYnMIPN+4M44Ob22aovn+R7msgEFZb7kV0kjCam7AJPaeRPuwOTM6TSCPjREL\nfG5Kt2XKAfDngwLOMQVXvkIi3+j/+WBoOFh1eeWINC3KaExRmfE23B+6yf102dXC\nDRmAISwtbZat69jrQKgLU6LcYMYdQvTtnqN+7cbOYQKBgQD+znO7XqM1EUeStYR7\nu9q65f+nZuDyTm2ZQnJLroohz80IqTP+k7MCk+gi+XipJ7JxitWA0DlvGxDILH5N\nCE5hM/GhVQCOBjGZ+AazUFn49S5SAIHrfqiOaUkXQpF8+g4BYgBkbelsAXV9nl7o\ntqVZl+W11Cmemm6KDuxkpnocpwKBgQDeXEajSVPLmM4TGt3zAirtXDb50yCWFoqw\nYzXPuG9SjBJqE8f9ObOaqwNV5JQsrX3JbO+34PMToTOX7o/xVPi+InG+Tlif6zOK\n8y9UVzBlFReM/oVwDJfpDzHAavf+Kt2S4DRF5xqf97GEb62hGkaHbZflIhIrugS8\nbS/Ov8PhFQKBgQDeG8ooDtOHQ5u3F8D3NoXwmuIh4vy8Wn8QtCn7LJa96GxaW1u2\nUrscyR71ta5nDPJwJMv88ATQg7A6PQaPUWk5M9Uxg23rXxzHkLsOfUEgUWBiHI0j\nYRG+qaoLu3wki7e/ntSmtmRdQFxQ9sbWZbd2hIC44cqxtP4cG+wVxEP3SwKBgAEf\ngC/U7/poRCouiY5vpV3biF+MpG59oKexaJUq/kzxbipg/TKXNwQB9xtY8zKika8R\nwMgx96hSuRr8VnfGkRcMv3xRkvsDyhfakJOheRoZmCvbITtmpOHFdN/e6m+7MbFL\nNphfyW+jZZ8gnUTiCBcpA4phuKvF3b5B4urtZwTdAoGBAKd0Aznb5jQ4IhRgwO8Y\nskZC+HCk3tQYTafJW9vOJDT8NEWclP7nPeplSIU3wVxXX7f0nLi9oREzTybEN1ft\nhYgPm1eN0t5DCs3jf3I8ATzLdOvN0ZvjrdPGJzPJ7UxFrL1wkVDQDzlmPsBUcLQz\nTa+V29uz/6yUE22XyrTiRw8s\n-----END PRIVATE KEY-----\n'
EOF
}


setup_gunicorn_service() {
    cat <<EOF | sudo tee /etc/systemd/system/Qcomm_SignageGunicorn.service >/dev/null
[Unit]
Description=Qcomm_Signage Dev Gunicorn
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
WorkingDirectory=${CURRENT_DIR}/Qcomm_Signage
ExecStart=${CURRENT_DIR}/Qcomm_Signage/env/bin/gunicorn --access-logfile - --workers 8 --threads 8 -t 600 --bind 127.0.0.1:7777 alerts.wsgi:application
EnvironmentFile=${CURRENT_DIR}/Qcomm_Signage/alerts/.env

[Install]
WantedBy=multi-user.target
EOF

        # Reload systemd and restart Gunicorn service
        sudo systemctl daemon-reload
        sudo systemctl start Qcomm_SignageGunicorn.service

}




configure_nginx() {
    if [[ "$enable_ssl" == "y" ]]; then
    cat <<EOF | sudo tee /etc/nginx/sites-available/Qcomm_SignageNginx.conf >/dev/null
    server {
        listen 443 ssl;
        server_name $backend_domain_name www.$backend_domain_name;
        client_max_body_size 100M;
        server_tokens off;
        location = /favicon.ico { access_log off; log_not_found off; }
        location /static/ {
           root ${CURRENT_DIR}/Qcomm_Signage;
        }
        location /media {
           root ${CURRENT_DIR}/Qcomm_Signage;
        }

        location / {
            include proxy_params;
            proxy_pass http://127.0.0.1:7777;
        }
        proxy_connect_timeout   600;
        proxy_send_timeout      600;
        proxy_read_timeout      600;
        send_timeout            600;
        client_body_timeout     600;

        ssl_certificate $backend_ssl_certificate_path;
        ssl_certificate_key $backend_ssl_certificate_key_path;
    }

    server {
        listen 443 ssl;
        server_name $frontend_domain_name www.$frontend_domain_name;
        server_tokens off;
        root ${CURRENT_DIR}/Qcomm_Frontend;
        index index.html index.htm index.nginx-debian.html;
        location / {
                try_files \$uri \$uri/ /index.html;
        }

        ssl_certificate $frontend_ssl_certificate_path;
        ssl_certificate_key $frontend_ssl_certificate_key_path;
    } 
EOF
else
    cat <<EOF | sudo tee /etc/nginx/sites-available/Qcomm_SignageNginx.conf >/dev/null
    server {
        # listen 443 ssl;
        listen $port_number;
        server_name $backend_domain_name www.$backend_domain_name;
        client_max_body_size 100M;
        server_tokens off;
        location = /favicon.ico { access_log off; log_not_found off; }
        location /static/ {
           root ${CURRENT_DIR}/Qcomm_Signage;
        }
        location /media {
           root ${CURRENT_DIR}/Qcomm_Signage;
        }

        location / {
            include proxy_params;
            proxy_pass http://127.0.0.1:7777;
        }
        proxy_connect_timeout   600;
        proxy_send_timeout      600;
        proxy_read_timeout      600;
        send_timeout            600;
        client_body_timeout     600;

        # ssl_certificate /home/user/innovationsbe.qcomm.co/fullchain.pem;
        # ssl_certificate_key /home/user/innovationsbe.qcomm.co/privkey.pem;

    }

    server {
        # listen 443 ssl;
        listen $port_number;
        server_name $frontend_domain_name www.$frontend_domain_name;
        server_tokens off;
        root ${CURRENT_DIR}/Qcomm_Frontend;
        index index.html index.htm index.nginx-debian.html;
        location / {
                try_files \$uri \$uri/ /index.html;
        }
        # ssl_certificate /home/user/innovationsbe.qcomm.co/fullchain.pem;
        # ssl_certificate_key /home/user/innovationsbe.qcomm.co/privkey.pem;

    }
EOF
fi

# Enable site and restart Nginx
sudo rm /etc/nginx/sites-enabled/default 
sudo ln -s /etc/nginx/sites-available/Qcomm_SignageNginx.conf /etc/nginx/sites-enabled/
sudo usermod -aG $(whoami) www-data
sudo nginx -t
sudo systemctl restart nginx
sleep 10 && sudo systemctl status nginx
}



create_background_service() {
    cat <<EOF | tee ${CURRENT_DIR}/Qcomm_Signage/background.sh >/dev/null
#!/bin/bash

# Navigate to the Qcomm_Signage directory
cd ${CURRENT_DIR}/Qcomm_Signage

# Activate the virtual environment
source env/bin/activate

# Run the Django management command to process tasks
python3.7 manage.py process_tasks
EOF

    # Change permissions of background.sh
    chmod +x ${CURRENT_DIR}/Qcomm_Signage/background.sh

    # Create Qcomm_SignageBackground.service
    cat <<EOF | sudo tee /etc/systemd/system/Qcomm_SignageBackground.service >/dev/null
[Unit]
Description=Qcomm_Signage Dev Background

[Service]
User=$(whoami)
WorkingDirectory=${CURRENT_DIR}/Qcomm_Signage
ExecStart=/bin/bash ${CURRENT_DIR}/Qcomm_Signage/background.sh

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd
    sudo systemctl daemon-reload

    # Restart Qcomm_SignageBackground.service
    sudo systemctl restart Qcomm_SignageBackground.service

    # Start Qcomm_SignageBackground.service on boot
    sudo systemctl enable Qcomm_SignageBackground.service

    # Check status of Qcomm_SignageBackground.service
    sleep 10 && sudo systemctl status Qcomm_SignageBackground.service
}


unattended_services() {
    systemctl is-active --quiet unattended-upgrades || {
        echo "Restarting unattended-upgrades service..."
        sudo systemctl start unattended-upgrades
    }
    echo "Deployment script completed successfully."
}





#main flow of the script


ask_for_prompt

install_essentials

unzipping_folders

install_python

install_nginx

setup_virtualenv

# Install Django and Gunicorn
pip3.7 install django gunicorn
gunicorn --version

# Create logs directory
mkdir logs

pip3.7 install drf-api-logger
pip3.7 install pandas

installation_libraries

install_mysql

setup_mysql

deactivate

create_env_file

setup_gunicorn_service

configure_nginx

create_background_service

unattended_services