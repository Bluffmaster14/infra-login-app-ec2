# Infra Login App on AWS EC2

This project provisions an EC2 instance with Terraform, installs Tomcat via a startup script,
and deploys a simple Java login web application. It also includes a Jenkins pipeline to build
and deploy the application.

## Architecture

- AWS EC2 (t2.micro) running Tomcat
- Java web application (JSP/Servlet)
- Terraform for infrastructure as code
- Jenkins pipeline for CI/CD

## Repo structure

- `terraform/` – Terraform code to provision EC2 + security group + key pair
- `loginapp/` – Java web application (JSP/Servlet, WAR build)
- `jenkinsfile` – Jenkins pipeline for build & deploy
- `tomcatstart.sh` – User-data / bootstrap script to install & start Tomcat

## What this project demonstrates

- Writing Terraform to provision AWS EC2
- Automating server bootstrap with shell script
- Packaging a Java web app as a WAR
- CI/CD with Jenkins (build → test → deploy)

## Prerequisites

- Terraform >= 1.x
- AWS account & IAM user
- Java + Maven
- Jenkins server with necessary plugins

## How to run

1. Clone the repo
2. Configure AWS credentials
3. `cd terraform && terraform init && terraform apply`
4. Note the EC2 public IP from terraform output
5. Build app: `cd ../tomcatapp && mvn clean package`
6. Deploy via Jenkins (pipeline uses this repo & WAR)

