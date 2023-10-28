#!/bin/bash

sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get install -y python3.7
sudo apt-get install -y python3.7-venv
sudo apt-get install -y build-essential
sudo apt-get install -y libmysqlclient-dev
sudo apt-get install -y python3.7-dev

python3.7 -m venv test
source test/bin/activate
pip install pip --upgrade
git clone https://github.com/kevingonzalez7997/Automate_Terraform_D6.git
cd Automate_Terraform_D6
pip install -r requirements.txt
pip install mysqlclient
pip install gunicorn
python database.py
sleep 1
python load_data.py
sleep 1 
python -m gunicorn app:app -b 0.0.0.0 -D
