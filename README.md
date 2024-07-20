# sample-fargate-webapp

Sample web app deployed as container on AWS via the Fargate service using Terraform.

## High Level Design

![high_level_diagram.png](images/high_level_diagram.png)

Approved changes made to the application's source code trigger generation of a new
docker container image stored in Elastic Container Registry.
The latest image is then deployed as a Fargate task.
End users can access the application by using a DNS record pointing to the
Application Load Balancer deployed to route traffic to the Fargate task.

## Process Workflow

![development_workflow.png](images/development_workflow.png)

Each time a developer commits code to the repo the CI process is triggered and
runs a number of automated tests to make sure everything is ok with the changes.
If errors occur the developer must fix it with new commits.
If everything is ok PR can be opened to merge the changes into the main branch.
Once the PR is merged the CD process triggers to deploy new version of the app.

## Areas of Improvement

* The infrastructure part of the code can be moved to a separate git repo so that
this repo is only for the application's source code. 
* The CI/CD process can be improved to one of the following:
  * everything can be moved inside AWS for seamless integration
  * if still using Github actions the AWS credentials can be done via OIDC provider  
  instead of using programmatic access via key.
  * The CI tests can be bundled in a container so that they are maintained centrally
  outside the scope of this app repo.

## Requirements

* AWS account
* Secret / access Key pair for authentication as an IAM user
* That IAM user should have sufficient permissions to deploy the infrastructure

## Repo structure

### application

The application folder contains:

* the actual app code that will be packaged in the container
* the requirements / dependencies needed
* the Dockerfile for the image creation

### helpers

Contains python script that creates the S3 bucket needed for storing
the terraform state if it doesn't exist.

### images

The Lucid diagrams used in the README.

### infrastructure

Contains the terraform code that creates the required AWS infrastructure 
for the app to be deployed in.