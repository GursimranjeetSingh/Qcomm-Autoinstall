# Exit script immediately if any command exits with a non-zero status
set -e

# Function to detect the OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo "Detected OS: $OS"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to wait for the apt lock to be released (Ubuntu specific)
wait_for_apt_lock() {
    while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
        echo "Waiting for other apt processes to finish..."
        sleep 5
    done
}


# Function to install essential packages
install_essentials() {
    if [ "$OS" = "ubuntu" ]; then
        sudo apt clean
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev unzip
        sudo apt install -y libmysqlclient-dev libgl1-mesa-glx libgl1-mesa-dri
     

    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum clean all
    sudo yum update -y

    # Check if it's RHEL and set the version
    if [ "$OS" = "rhel" ]; then
        rhel_version=$(rpm -E %{rhel})
    else
        rhel_version=$(rpm -E %{centos})
    fi

    # Echo the detected RHEL/CentOS version
    echo "Detected RHEL/CentOS version: $rhel_version"

    # Enable EPEL repository based on RHEL/CentOS version
    if [[ $rhel_version -eq 7 ]]; then
        sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    elif [[ $rhel_version -eq 8 ]]; then
        sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    elif [[ $rhel_version -eq 9 ]]; then
        sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    else
        echo "Unsupported RHEL/CentOS version: $rhel_version"
        exit 1
    fi

    sudo yum install -y gcc zlib-devel ncurses-devel openssl-devel sqlite-devel readline-devel libffi-devel wget bzip2-devel unzip
    sudo yum install -y mariadb-connector-c-devel
 


    
    else
        echo "Unsupported OS"
        exit 1
    fi
}


# unzipping_folders() {
#     if [ "$OS" = "ubuntu" ]; then
#         sudo apt install unzip
#         unzip SmartTicker.zip -d ${CURRENT_DIR}
#         mkdir -p ${CURRENT_DIR}/Qcomm_Frontend
#         mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/Qcomm_Frontend
#         cd ${CURRENT_DIR}/Qcomm_Frontend
#         unzip dist.zip
#         cd ${CURRENT_DIR}

#         # Create api_url.json and insert backend domain
#         cat <<EOF | tee ${CURRENT_DIR}/Qcomm_Frontend/api_url.json >/dev/null
# {
#     "backend_domain": "${PROTOCOL}://${backend_domain_name}"
# }
# EOF

#     elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
#         sudo yum install -y unzip
#         unzip SmartTicker.zip -d ${CURRENT_DIR}
#         mkdir -p ${CURRENT_DIR}/Qcomm_Frontend
#         mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/Qcomm_Frontend
#         cd ${CURRENT_DIR}/Qcomm_Frontend
#         unzip dist.zip
#         cd ${CURRENT_DIR}

#         # Create api_url.json and insert backend domain
#         cat <<EOF | tee ${CURRENT_DIR}/Qcomm_Frontend/api_url.json >/dev/null
# {
#     "backend_domain": "${PROTOCOL}://${backend_domain_name}"
# }
# EOF

#     else
#         echo "Unsupported OS"
#         exit 1
#     fi
# }

unzipping_folders() {
    if [ "$OS" = "ubuntu" ]; then
        sudo apt install unzip
        unzip Qcomm_Signage.zip -d ${CURRENT_DIR}
        mkdir -p ${CURRENT_DIR}/Qcomm_Frontend
        mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/Qcomm_Frontend
        cd ${CURRENT_DIR}/Qcomm_Frontend
        unzip dist.zip
        cd ${CURRENT_DIR}
        for file in ${CURRENT_DIR}/Qcomm_Frontend/main*; do
            sed -i 's|https://domain.com|'${PROTOCOL}://${backend_domain_name}'|g' "$file"
        done
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        sudo yum install -y unzip
        unzip Qcomm_Signage.zip -d ${CURRENT_DIR}
        mkdir -p ${CURRENT_DIR}/Qcomm_Frontend
        mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/Qcomm_Frontend
        cd ${CURRENT_DIR}/Qcomm_Frontend
        unzip dist.zip
        cd ${CURRENT_DIR}
        for file in ${CURRENT_DIR}/Qcomm_Frontend/main*; do
            sed -i 's|https://domain.com|'${PROTOCOL}://${backend_domain_name}'|g' "$file"
        done
    else
        echo "Unsupported OS"
        exit 1
    fi
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


setup_virtualenv() {
    if [ "$OS" = "ubuntu" ]; then
        cd ${CURRENT_DIR}/Qcomm_Signage
        sudo pip3.7 install virtualenv
        python3.7 -m virtualenv env
        source env/bin/activate
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        cd ${CURRENT_DIR}/Qcomm_Signage
        sudo /usr/local/bin/pip3.7 install virtualenv
        virtualenv env3
        source env/bin/activate
    fi
}


essential_library_for_databse(){
    if [ "$OS" = "ubuntu" ]; then
        sudo apt install -y libmysqlclient-dev
       
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
        sudo yum install -y mariadb-connector-c-devel

    fi
}


installation_libraries(){
    if [ "$OS" = "ubuntu" ]; then
        cd ${CURRENT_DIR}/Qcomm_Signage
        pip3.7 install -r requirements.txt
        sudo apt install -y libgl1-mesa-glx libgl1-mesa-dri
       
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
        cd ${CURRENT_DIR}/Qcomm_Signage
        pip3.7 install -r requirements.txt
    fi

}

# Function to install MySQL
install_mysql() {
    if [ "$OS" = "ubuntu" ]; then
        sudo apt install -y mysql-server
        sudo systemctl start mysql.service
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
        sudo yum install -y mariadb-server
        sudo systemctl start mariadb.service
    fi
}

# Function to install nginx
install_nginx() {
    if [ "$OS" = "ubuntu" ]; then
        sudo systemctl status nginx || sudo apt install -y nginx
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
        sudo systemctl status nginx || sudo yum install -y nginx
    fi
}



create_env_file() {
    cat <<EOF | sudo tee ${CURRENT_DIR}/Qcomm_Signage/alerts/.env >/dev/null
EMAIL_PASSWORD='Q@1~3eT51427'
ILAIT_EMAIL_PASSWORD="C\$M=3XHS"
FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDdUuDdDXy9b7Ho\nHz3L3tgYS62ikgnR9gHOZajmAdUse3X/JS2h6iSiZkWoDYnQJnKdnKf8WRwUdmwS\nIDJE6sdr4XOXZB8qGcMGcPQ+4PzHtiOaAIMESN/26afo2uu+FLnzsfFBQz4S/qIC\nuHpJMNhCNmbA39xA+jZDmYoRGuq7vuDA8Qg+JSt0zpkv6gZWIVkeuOyjJY6GBCqh\nLLRkbpkIGtOxcBiOvWSGXixjnJm7jqDmbmm+SroUvFn1eZi/LzOc75fKn4vlXnPW\nm+6hFydD3z/F/ogyG26sXXNZdzKRgDwqgUnCIuWyp2HIsLvaN4nSskqAMj4pWNJ+\nfFlnaCCzAgMBAAECggEAaTdhVzV2O8jB1wwjIKyMJuCzZznuGTbOnQSPSulMIp1+\n9xEBpJvfVqUwMDhfb+kXS/6RjdH/G2tA7U0JGOJUc+D2Rt5+QlGE+abxNoNXKMpa\nGnhr0LmkX4mtHXIV6IOJ82SAwPnqpLUQ6CIzYGAsLy4Vo1PJLcrFyVVQ4djeBupQ\nrjTGYnMIPN+4M44Ob22aovn+R7msgEFZb7kV0kjCam7AJPaeRPuwOTM6TSCPjREL\nfG5Kt2XKAfDngwLOMQVXvkIi3+j/+WBoOFh1eeWINC3KaExRmfE23B+6yf102dXC\nDRmAISwtbZat69jrQKgLU6LcYMYdQvTtnqN+7cbOYQKBgQD+znO7XqM1EUeStYR7\nu9q65f+nZuDyTm2ZQnJLroohz80IqTP+k7MCk+gi+XipJ7JxitWA0DlvGxDILH5N\nCE5hM/GhVQCOBjGZ+AazUFn49S5SAIHrfqiOaUkXQpF8+g4BYgBkbelsAXV9nl7o\ntqVZl+W11Cmemm6KDuxkpnocpwKBgQDeXEajSVPLmM4TGt3zAirtXDb50yCWFoqw\nYzXPuG9SjBJqE8f9ObOaqwNV5JQsrX3JbO+34PMToTOX7o/xVPi+InG+Tlif6zOK\n8y9UVzBlFReM/oVwDJfpDzHAavf+Kt2S4DRF5xqf97GEb62hGkaHbZflIhIrugS8\nbS/Ov8PhFQKBgQDeG8ooDtOHQ5u3F8D3NoXwmuIh4vy8Wn8QtCn7LJa96GxaW1u2\nUrscyR71ta5nDPJwJMv88ATQg7A6PQaPUWk5M9Uxg23rXxzHkLsOfUEgUWBiHI0j\nYRG+qaoLu3wki7e/ntSmtmRdQFxQ9sbWZbd2hIC44cqxtP4cG+wVxEP3SwKBgAEf\ngC/U7/poRCouiY5vpV3biF+MpG59oKexaJUq/kzxbipg/TKXNwQB9xtY8zKika8R\nwMgx96hSuRr8VnfGkRcMv3xRkvsDyhfakJOheRoZmCvbITtmpOHFdN/e6m+7MbFL\nNphfyW+jZZ8gnUTiCBcpA4phuKvF3b5B4urtZwTdAoGBAKd0Aznb5jQ4IhRgwO8Y\nskZC+HCk3tQYTafJW9vOJDT8NEWclP7nPeplSIU3wVxXX7f0nLi9oREzTybEN1ft\nhYgPm1eN0t5DCs3jf3I8ATzLdOvN0ZvjrdPGJzPJ7UxFrL1wkVDQDzlmPsBUcLQz\nTa+V29uz/6yUE22XyrTiRw8s\n-----END PRIVATE KEY-----\n'
EOF
}


# Function to set up Gunicorn service

setup_gunicorn_service() {
    if [ "$OS" = "ubuntu" ]; then
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
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
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

        # Check permissions for gunicorn executable
        ls -l ${CURRENT_DIR}/Qcomm_Signage/env/bin/gunicorn

        # Check permissions for the directories
        ls -ld ${CURRENT_DIR}
        ls -ld ${CURRENT_DIR}/Qcomm_Signage
        ls -ld ${CURRENT_DIR}/Qcomm_Signage/env
        ls -ld ${CURRENT_DIR}/Qcomm_Signage/env/bin

        # Update permissions for directories
        chmod +x ${CURRENT_DIR}
        chmod +x ${CURRENT_DIR}/Qcomm_Signage
        chmod +x ${CURRENT_DIR}/Qcomm_Signage/env
        chmod +x ${CURRENT_DIR}/Qcomm_Signage/env/bin

        # Update permissions for gunicorn executable
        chmod +x ${CURRENT_DIR}/Qcomm_Signage/env/bin/gunicorn

        source ${CURRENT_DIR}/Qcomm_Signage/env/bin/activate
        pip show gunicorn
        sestatus

        sudo setenforce 0

        sudo systemctl daemon-reload
        sudo systemctl start Qcomm_SignageGunicorn.service
    fi
}




configure_nginx() {
    if [ "$OS" = "ubuntu" ]; then
       # Construct Nginx configuration based on SSL option
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

        ssl_certificate $backend_ssl_certificate;
        ssl_certificate_key $backend_ssl_certificate_key;
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

        ssl_certificate $frontend_ssl_certificate;
        ssl_certificate_key $frontend_ssl_certificate_key;
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
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
       if [[ "$enable_ssl" == "y" ]]; then
    cat <<EOF | sudo tee /etc/nginx/conf.d/Qcomm_SignageNginx.conf >/dev/null
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
        # include proxy_params;
        proxy_pass http://127.0.0.1:7777;
    }

    proxy_connect_timeout   600;
    proxy_send_timeout      600;
    proxy_read_timeout      600;
    send_timeout            600;
    client_body_timeout     600;

    ssl_certificate $backend_ssl_certificate;
    ssl_certificate_key $backend_ssl_certificate_key;

}

server {
    listen 443 ssl;
    server_name $frontend_domain_name www.$frontend_domain_name;
    client_max_body_size 100M;
    server_tokens off;
    root ${CURRENT_DIR}/Qcomm_Frontend;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    ssl_certificate $frontend_ssl_certificate;
    ssl_certificate_key $frontend_ssl_certificate_key;
   
}
EOF
else
    cat <<EOF | sudo tee /etc/nginx/conf.d/Qcomm_SignageNginx.conf >/dev/null
server {
    # listen 443 ssl;
    listen $port_number;
    server_name $backend_domain_name www.$backend_domain_name;
    server_tokens off;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
       root ${CURRENT_DIR}/Qcomm_Signage;
    }
    location /media {
       root ${CURRENT_DIR}/Qcomm_Signage;
    }

    location / {
        # include proxy_params;
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

# Add your user to the nginx group
sudo usermod -aG nginx $(whoami)

# Test the Nginx configuration
sudo nginx -t

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx
sudo systemctl enable nginx

# Check the status of Nginx to ensure it is running
sleep 10 && sudo systemctl status nginx
    fi
}



create_background_service() {
    if [ "$OS" = "ubuntu" ]; then
       # Create background.sh script
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
    elif [ "$OS" = "centos" ]|| [ "$OS" = "rhel" ]; then
        # Create background.sh script
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

    fi
}



configure_firewall() {
    if [ "$OS" = "rhel" ]; then
        sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
        sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
        sudo firewall-cmd --reload
    else
        echo "Firewall configuration only required for RHEL."
    fi
}


unattended_services() {
    if [ "$OS" = "ubuntu" ]; then
        if ! systemctl is-active --quiet unattended-upgrades; then
            echo "Restarting unattended-upgrades service..."
            sudo systemctl start unattended-upgrades
        fi
        echo "Deployment script completed successfully."
    else
        echo "No unattended-upgrades services to start"
    fi
}




# Main script execution starts here

# Detect the OS
detect_os

CURRENT_DIR=$(pwd)

# If Ubuntu, stop unattended-upgrades service and wait for apt lock
if [ "$OS" = "ubuntu" ]; then
    sudo systemctl stop unattended-upgrades.service || true
    wait_for_apt_lock
fi

# Set Git environment variables to prevent username/password prompts
export GIT_TERMINAL_PROMPT=0

# Prompt user for domain name for backend
read -p "Enter the domain for backend (e.g., example.com): " backend_domain_name

# Prompt user for domain name for frontend
read -p "Enter the domain for frontend (e.g., example.com): " frontend_domain_name

# Prompt user if SSL should be enabled
read -p "Do you want to enable SSL? (y/n): " enable_ssl

# Variables for SSL configuration
backend_ssl_certificate=""
backend_ssl_certificate_key=""
frontend_ssl_certificate=""
frontend_ssl_certificate_key=""

# If SSL is enabled, prompt for certificate paths and adjust port number
if [[ "$enable_ssl" == "y" ]]; then
    read -p "Enter the path to SSL certificate file for backend: " backend_ssl_certificate
    read -p "Enter the path to SSL certificate key file for backend: " backend_ssl_certificate_key
    read -p "Enter the path to SSL certificate file for frontend: " frontend_ssl_certificate
    read -p "Enter the path to SSL certificate key file for frontend: " frontend_ssl_certificate_key
    PROTOCOL="https"
else
    # Prompt user for port number if SSL is not enabled
    read -p "Enter the port number for Nginx to listen to (e.g., 80): " port_number
    PROTOCOL="http"
fi

# Install essential packages
install_essentials


#Unzipp the folders
unzipping_folders 

# Install Python 3.7.14
install_python


# Install nginx
install_nginx


# Set up and activate the virtual environment
setup_virtualenv


# Install Django and Gunicorn
pip3.7 install django gunicorn
gunicorn --version

# Create logs directory
mkdir logs

pip3.7 install drf-api-logger
pip3.7 install pandas


essential_library_for_databse

installation_libraries

install_mysql



read -p "Do you want to set up a MySQL database? (y/n): " setup_mysql

if [[ "$setup_mysql" == "y" ]]; then
    # Clean up MySQL and create a new database and user with privileges
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

    # Create a configuration file with MySQL details in JSON format
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


echo "Creating SuperUser............................................."
python3.7 manage.py createsuperuser


# python3.7 manage.py shell <<EOF
# from django.contrib.auth.models import User

# # Check if 'Admin' user exists, create if not
# if not User.objects.filter(username='Admin').exists():
#     User.objects.create_superuser('Admin', '', 'Acer#555')
#     print('Superuser "Admin" created with password "Acer#555"')
# else:
#     print('Superuser "Admin" already exists')
# EOF


# Deactivate virtual environment
deactivate

create_env_file

setup_gunicorn_service

#Crete env file for passwords


# Configure Nginx
configure_nginx

# Create Qcomm_SignageBackground service
create_background_service

configure_firewall

unattended_services
