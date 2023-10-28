#!/bin/bash

#!/bin/bash

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.7 
sudo apt-get install -y python3.7-venv 
sudo apt-get install -y build-essential 
sudo apt-get install -y libmysqlclient-dev 
sudo apt-get install -y python3.7-dev


# Create and activate virtual environment
python3.7 -m venv test
source test/bin/activate
curl -O https://raw.githubusercontent.com/kevingonzalez7997/Automate_Terraform_D6/main/jenkin_and_agent/jenkins_install.sh
cd Automate_Terraform_D6
pip install pip --upgrade
pip install -r requirements.txt
# Install required packages in the virtual environment
pip install mysqlclient
pip install gunicorn
python database.py
python load_data.py
python -m gunicorn app:app -b 0.0.0.0 -D && echo "Done"
source test/bin/activate
