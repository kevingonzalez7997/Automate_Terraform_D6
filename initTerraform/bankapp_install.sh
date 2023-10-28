#!/bin/bash

python3.7 -m venv test
source test/bin/activate
pip install gunicorn mysqlclient
git clone https://github.com/kevingonzalez7997/Automate_Terraform_D6.git
cd Automate_Terraform_D6
pip install -r requirements.txt
python database.py
sleep 1
python load_data.py
sleep 1 
gunicorn app:app -b 0.0.0.0
