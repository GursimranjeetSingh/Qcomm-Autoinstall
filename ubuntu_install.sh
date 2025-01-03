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
machine_ip= $(hostname -I | cut -d' ' -f1)
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
        echo 'Qcomm will be running on http://' + $machine_ip + '/'
        backend_domain_name=$machine_ip + ':8000'
    fi

    read -p "Do you want to set up a MySQL database? (y/n): " setup_mysql
}

install_essentials() {
    sudo apt clean
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev wget libbz2-dev unzip
    sudo apt install -y libmysqlclient-dev libgl1-mesa-glx libgl1-mesa-dri

}

unzipping_folders(){
    sudo apt install unzip
    unzip Qcomm_Signage.zip -d ${CURRENT_DIR}
    mkdir -p ${CURRENT_DIR}/SmartTickerFrontend
    mv ${CURRENT_DIR}/dist.zip ${CURRENT_DIR}/SmartTickerFrontend
    cd ${CURRENT_DIR}/SmartTickerFrontend
    unzip dist.zip
    cd ${CURRENT_DIR}
    for file in ${CURRENT_DIR}/SmartTickerFrontend/main*; do
        sed -i 's|https://domain.com|'${PROTOCOL}://${backend_domain_name}'|g' "$file"

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

setup_mysql(){
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

}



#main flow of the script


ask_for_prompt

unzipping_folders

install_python

install_nginx

setup_virtualenv

installation_libraries

install_mysql

setup_mysql