# Sample Fargate Webapp

Sample web app deployed as container on AWS via ECS/Fargate using Terraform.

* [High Level Design](#hld)
* [Process Workflow](#pw)
* [CI/CD Process](#cicd)
  * [Continuous Integration](#ci)
  * [Continuous Deployment](#cd)
* [Areas of Improvement](#aoi)
* [Requirements](#req)
  * [Examples](#examples)
    * [s3.tfbackend](#tfbackend)
    * [input.auto.tfvars](#tfvars)
* [Repo Structure](#repostruct)
  * [application](#repoapp)
  * [images](#repoimages)
  * [infrastructure](#repoinfra)
* [How-To](#howto)
  * [Build Container Image](#howtobuild)
  * [Deploy to AWS](#howtodeploy)
* [Monitoring](#monitoring)
* [Acknowledgements](#ack)

## High Level Design <a name="hld"></a>

![high_level_diagram.png](images/high_level_diagram.png)

Approved changes made to the application's source code trigger generation of a new
docker container image stored in Elastic Container Registry.
The latest image is then used in a task definition for a Fargate service.
End users can access the application by using a DNS record pointing to the
Application Load Balancer deployed to route traffic to the Fargate service.

## Process Workflow <a name="pw"></a>

![development_workflow.png](images/development_workflow.png)

Each time a developer commits code to the repo as part of PR the CI process is 
triggered and runs a number of automated tests to make sure everything is ok 
with the changes both in terms of application code as well as in regards to the
infrastructure.
If errors occur the developer must fix it with new commits.
If everything is ok the changes in the PR can be merged into the main branch.
Once the PR is merged the CD process triggers to deploy new version of the app.

## CI/CD Process <a name="cicd"></a>

Two github actions workflows are defined for the continuous integration and 
the continuous delivery part  of the process. The CI workflow triggers only
when a PR is raised or updated which means you can commit and push as much as
you like but tests to your code are done once you want to merge these changes
in the main branch. There is a rule set in the repo that does not allow you to
merge if you have failed status checks.
Once your tests are ok and your changes are approved and merged to the main branch
the continuous deployment phase starts which builds and tags new container image
that includes your code changes and then updates the infrastructure to use it.

### Continuous Integration <a name="ci"></a>

* Application Tests
  * [Pylint](https://www.pylint.org/) - linter and static code analysis
  * [Bandit](https://github.com/PyCQA/bandit) - vulnerability scanning
* Infrastructure Tests
  * [TFLint](https://github.com/terraform-linters/tflint) - linter and static code analysis
  * [Tfsec](https://github.com/aquasecurity/tfsec) - security scanner

### Continuous Deployment <a name="cd"></a>

* Docker image build, tag & push to ECR
* Terraform apply with newly built image

## Areas of Improvement <a name="aoi"></a>

* The infrastructure part of the code can be moved to a separate git repo so that
this repo is only for the application's source code. 
* There is probably better implementation of the services. For example the ECR 
registry can be created as part of the infrastructure and have proper lifecycle 
policy. Since we are emphasizing on the CI/CD process here things are kept rather simple.
* If this was real world application deployment it should have been at least served
via https which would imply owning a domain and having a TLS cert used in ACM.
* Docker images can be created in one central account and can be additionally scanned
by AWS Inspector.
* Multiple accounts can be created for each environment necessary and deployments of 
the central account's images can be done to each environment
* The CI/CD process can be improved to one of the following:
  * everything can be moved inside AWS for seamless integration
  * if still using Github actions the AWS credentials can be done via OIDC provider  
  and role instead of using programmatic access via key and IAM user.
  * The CI tests can be bundled in a container so that they are maintained centrally
  outside the scope of this app repo.
  * Environment-based deployments can be configured to first deploy in UAT env.
  and then in prod
  * Some policy-as-code tool (like OPA) can be implemented to control what changes 
  are allowed to the infra or app code via custom rules.
  * The deployment could implement blue/green or canary approach to validate if change
  is ok and limit impact when errors are present
  * Proper SAST/DAST/SCA tools like SonarQube, Burp Suite & OpenSCA can be implemented
  for complete code evaluation

## Requirements <a name="req"></a>

* AWS account
* Secret / access Key pair for authentication as an IAM user (added as git repo secrets)
and that IAM user should have sufficient permissions to deploy the infrastructure
* The S3 bucket used for terraform state must already exist
* The ECR Repo to store the container images must already exist

### Examples <a name="examples"></a>

#### s3.tfbackend <a name="tfbackend"></a>

```hcl
bucket = "my-unique-random-bucket-name"
key = "sample-fargate-webapp/terraform.tfstate"
region = "eu-west-1"
```

#### input.auto.tfvars <a name="tfvars"></a>

```hcl
region = "eu-west-1"
env = "staging"
```

## Repo Structure <a name="repostruct"></a>

### application <a name="repoapp"></a>

The application folder contains:

* the actual app code that will be packaged in the container
* the requirements / dependencies needed
* the Dockerfile for the image creation

### images <a name="repoimages"></a>

The Lucid diagrams used in the README.

### infrastructure <a name="repoinfra"></a>

Contains the terraform code that creates the required AWS infrastructure 
for the app to be deployed in.

## How-To <a name="howto"></a>

### Build Container Image <a name="howtobuild"></a>

1. Make sure requirements are met (ECR repo, IAM role)
2. `cd application`
3. Assume the IAM role with sufficient permissions
4. `aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com`
5. `docker build -t flask-webapp .`
6. `docker tag flask-webapp:latest <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/flask-webapp:latest`
7. `docker push <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/flask-webapp:latest`

### Deploy to AWS <a name="howtodeploy"></a>

1. Make sure requirements are met (S3 bucket, ECR repo, IAM role)
2. `cd infrastructure`
3. Assume the IAM role with sufficient permissions
4. Adjust the `tfbackend` and `tfvars` files to work for you (i.e. change the bucket name)
5. `export TF_VAR_image_tag=latest`
6. `terraform init -backend-config=s3.tfbackend && terraform apply`

## Monitoring <a name="monitoring"></a>

Once deployed this app can be monitored as follows:

* Configure CloudWatch alarms for the Fargate service, ALB metrics
* If DNS was setup for the app in Route53 then URL health checks can 
also be configured
* App data can be exported via XRay or OpenTelemetry for app tracing
* Sidecar prometheus container can be added in the deployment so that
data gathered can be then visualized and monitored via Grafana
* Sidecar Fluent Bit container can be added to ingest app logs into
Opensearch for analysis

## Acknowledgements <a name="ack"></a>

The following third-party terraform code by [Anton Babenko](https://www.antonbabenko.com/)
was used for convenience:

* [VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
* [ALB](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
* [ECS](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest)
