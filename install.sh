#!/bin/bash


PYTHON_INTERPRETER=$(which python3.6)
DOMAIN_NAME="djtest.loc"
PORT=80
PROJECT_ROOT_DIR="/tmp/test"
PROJECT_NAME="djtest"

PROJECT_PATH=$PROJECT_ROOT_DIR/$PROJECT_NAME

echo Use: $PYTHON_INTERPRETER
echo Domain: $DOMAIN_NAME
echo Project: $PROJECT_PATH

pwd && ls


mkdir -p $PROJECT_PATH

cp -Rf  gunicorn $PROJECT_PATH/gunicorn

cp -Rf  nginx $PROJECT_PATH/nginx

sed -i "s~<project_path>~$PROJECT_PATH~g" $PROJECT_PATH/nginx/site.conf
sed -i "s~<domain_name>~$DOMAIN_NAME~g" $PROJECT_PATH/nginx/site.conf
sed -i "s~<project_name>~$PROJECT_NAME~g" $PROJECT_PATH/nginx/site.conf
sed -i "s~<port>~$PORT~g" $PROJECT_PATH/nginx/site.conf

sudo ln -sf $PROJECT_PATH/nginx/site.conf /etc/nginx/sites-enabled/$DOMAIN_NAME.conf
sudo ln -sf $PROJECT_PATH/nginx/site.conf /etc/nginx/conf.d/$DOMAIN_NAME.conf

cp -Rf  systemd $PROJECT_PATH/systemd

sed -i "s~<project_path>~$PROJECT_PATH~g"  $PROJECT_PATH/systemd/gunicorn.service
sed -i "s~<project_name>~$PROJECT_NAME~g"  $PROJECT_PATH/systemd/gunicorn.service
sed -i "s~<user_name>~vladimir~g"          $PROJECT_PATH/systemd/gunicorn.service

sudo ln -sf $PROJECT_PATH/systemd/gunicorn.service /etc/systemd/system/$PROJECT_NAME.service
sudo python3.6 -c "import socket as s; sock = s.socket(s.AF_UNIX); sock.bind('$PROJECT_PATH/gunicorn/$PROJECT_NAME.sock')"
sudo chmod -R 777 $PROJECT_PATH/gunicorn/$PROJECT_NAME.sock

cp requirements.txt $PROJECT_PATH/requirements.txt

cd $PROJECT_PATH

pwd && ls

$PYTHON_INTERPRETER -m venv  $PROJECT_PATH/env

pwd && ls

source  $PROJECT_PATH/env/bin/activate

pip install -U pip
pip install -r requirements.txt

django-admin startproject $PROJECT_NAME

pwd && ls

sed -i "s/\\ALLOWED_HOSTS.*=.*/\\ALLOWED_HOSTS = [\'$DOMAIN_NAME\']/g;" $PROJECT_PATH/$PROJECT_NAME/$PROJECT_NAME/settings.py
sed -i "s/\\STATIC.*=.*/\\STATIC = \'$PROJECT_PATH\/static/\'/g;" $PROJECT_PATH/$PROJECT_NAME/$PROJECT_NAME/settings.py
echo "STATIC_ROOT = '$PROJECT_PATH/static/'" >> $PROJECT_PATH/$PROJECT_NAME/$PROJECT_NAME/settings.py
mkdir $PROJECT_PATH/static

#sudo chmod -R 755 $PROJECT_PATH/static

cd $PROJECT_PATH/$PROJECT_NAME

pwd && ls

python3.6 manage.py migrate
python3.6 manage.py collectstatic
python3.6 manage.py createsuperuser

echo "127.0.0.1 $DOMAIN_NAME" | sudo tee -a /etc/hosts

sudo systemctl daemon-reload
sudo systemctl  restart gunicorn
sudo systemctl enable gunicorn
sudo systemctl  restart nginx
systemctl status gunicorn
echo -e "\nProject is running: http://$DOMAIN_NAME/\n"



