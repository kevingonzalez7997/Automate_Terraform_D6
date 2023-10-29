# Utlizing Terraform with Jenkins to Provision App Infrastructure (6)
### October 28, 2023
### Kevin Gonzalez

## Purpose

This deployment aims to streamline Terraform's stages using Jenkins while provisioning the application's infrastructure. The application now spans two regions and four Availability Zones (AZs). An application load balancer is implemented for distributing traffic, and for multi-regional support, RDS handles the database across regions.

## Deployment Steps

### 1. Jenkins Infrastructure

Terraform, an open-source Infrastructure as Code (IaC) tool, simplifies infrastructure management with its declarative configuration language. It supports multiple cloud providers and enables efficient provisioning.

In this deployment, Terraform is used to create the [Jenkins infrastructure](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/jenkin_and_agent/main.tf), which includes two instances, the manager, and the node. The [jenkins_install](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/jenkin_and_agent/jenkins_install.sh) script has been created to install Jenkins Manager and its dependencies. The [terraform](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/jenkin_and_agent/terraform.sh) script has been created to install Terraform and its dependencies.

### 2. Generate Two New Key Pairs in AWS

To launch Jenkins agents for hosting the application, SSH is used, and private keys are required. Additionally, resources are not cross-regional, so EC2 instances deployed in us-west-1 will need new keys.

- Navigate to EC2 in the AWS console.
- Under Network & Security, find Key Pairs.
- Create a new pair and save the private key.
- Change region and repeat steps for us-west-1.

### 3. Jenkins Agents

Jenkins, an open-source automation server, is used for building, testing, and deploying code, and it can distribute workloads.

- Create a new node.
- Specify name and location.
- Select "Launch agent via SSH" (using the previously generated key).
- The host will be the public IP of the agent instance (Agent_ec2).
- Create credentials by entering the private key directly.
- Save and check the [log](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/Images/Agent_running.png) to verify agent status.

### 4. Git / GitHub

Git is a widely used distributed version control system (DVCS) for tracking changes in source code during software development. GitHub, a web-based platform, provides hosting for Git repositories and is one of the most popular platforms for version control and collaborative software development.

In this deployment, [git](https://github.com/kevingonzalez7997/Git_Cloning) is used to create a second branch that will host the source code for the application in the west region [branch](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/Images/MultiBranch.png). Each branch will host a single Terraform file, allowing for isolation, and changes can be made to a specific region more easily.

### 5. Application Infrastructure

The Jenkins node previously created will use Terraform to launch two application infrastructures across two regions. Each infrastructure will include the following [resources](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/initTerraform/main.tf):

- 1 Virtual Private Cloud (VPC)
- 2 Availability Zones (AZs)
- 2 Public Subnets
- 2 EC2 instances
- 1 Route Table
- Security Group with ports: 8000 and 22
-Load balancer
-Listener
-Target group 

### 6. Configure AWS Access Keys in Jenkins

To give Terraform access to the AWS account, both access and secret keys must be included. Since GitHub is the Source Code Management (SCM), this part of the Terraform file cannot be included. Instead, AWS keys will be stored securely in Jenkins.

In Jenkins server:
- Manage Jenkins
  - Credentials
    - System
      - Global credentials (unrestricted)
        - Create 2 credentials (access and secret key)
          - "Secret text"

### 7. Creating RDS Database

For the application, the free tier MySQL will be used.
- Select the free tier.
- Create and save a password.
- Allow public access.
- Name and create the database.
- A default security group will be created, and port 3306 will be opened. This will allow the information entered on either region application to write and read to the database.
- In order to connect them, three files will be edited with the password created, database endpoint, and database name. The database.py, load_data.py, and app.py will be edited in both branches.

### 8. Create [appsetup.sh](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/initTerraform/appsetup.sh)

As the application is manually executed using bash commands, I could optimize the deployment process by reusing the installation steps from the previous deployment as the foundation for our build script. The key distinction lies in the addition of 'pip install mysqlclient' to the script This build script is incorporated into the Terraform file, enabling the automatic deployment of our application when the resource is created.

### 9. Jenkins Pipeline

GitHub is one of the most popular open-source repository platforms. The code will be pulled from a GitHub repository that has been created, which is a more practical approach.

- Create a new Jenkins item and select "Multi-branch pipeline."
- Configure Jenkins Credentials Provider as needed.
- Copy and import the Repository URL where the application source code resides.
- Use your GitHub username and the generated key from GitHub as your credentials.
- Run [Build](https://github.com/kevingonzalez7997/Automate_Terraform_D6/blob/main/Images/Jenkin_steps.png)


## Troubleshooting
If there are connection issues with EC2:
Although a default route table is created by Terraform it still has to be attached to the IGW. Be sure to include the following 
- `resource "aws_default_route_table" "route5_1" {
  default_route_table_id = aws_vpc.d5-1_vpc.default_route_table_id
   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}`
- when creating the app in appsetup.sh be sure not to use '_' character in the file name as it causes issues.
### Optimization

While the deployment is successful, there are opportunities for optimization and further enhancements. Here are some areas to consider for future improvements:

- **Containerization with Docker**: Consider containerizing components of your application using Docker to further automate and streamline the deployment process. Docker images can encapsulate all dependencies and simplify the deployment workflow.

- **Three-Tier Architecture**: Exploring a three-tier application architecture can enhance security and data isolation. Separating the presentation, application, and data layers can improve scalability and restrict access to sensitive data.

## Conclusion
In conclusion, this deployment successfully leveraged Terraform and Jenkins to automate infrastructure provisioning. The application now spans multiple regions, benefiting from enhanced resilience and load balancing. Jenkins streamlined our CI/CD pipeline and secured AWS key management. 
