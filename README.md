# CSYE 6225 - Fall 2019

## Team Information

| Name | NEU ID | Email Address |
| --- | --- | --- |
| Harshitha Somasundar |001497986 | somasundar.h@husky.neu.edu |
| Shuravi Barman | 001475070 | barman.s@husky.neu.edu |
| Bhashmi Dineshbhai Fatnani |  001449268 |  fatnani.b@husky.neu.edu|
| | | |

## Technology Stack
Server Side:
Spring boot(JAVA)
services
Entities(user)
Entities(Recipe)
Entities(Nutrition information)
hibernate
MYSQL(databse)

## Build Instructions
1.Run .mvn clean install to build the war.


## Deploy Instructions
1. Run the Terraform policies, to create policies for IAM circleCI user ,using terraform apply (provide aws region and bucket name)
2. Run the code deploy to create a custom AMI using CIRCLECI (configure environment variables like AWS keys, bucketname and region)
3.Run the Terraform to create all the resources required for the instance ( creates EC2, RDS, dynamodb , S3 bucket)
4.Run this webapp codedeploy using CIRCLECI.
5. Take the IP created from instance and hot all the POST,GET, DELETE API's


## Running Tests
1. Tests are on Springrunner junit5 class
2. used @Sprinboottest annotations to denote test class 
3. Mocked services to use method like findbyId and findbyUsername
4. Unit test cases for all api's along with integration testing

## CI/CD
1. CircleCI is used th deploy the webapp code
2. Use the api : " curl -u <PERSONAL_OR_PROJECT_TOKEN> \
                      -d build_parameters[CIRCLE_JOB]=build \
                      https://circleci.com/api/v1.1/project/github/tejasparikh/csye6225-spring2019-ami/tree/master"  to trigger the CircleCI job                  
3. the job consists of environment variables like AWS acesskeys, bucket name and region , also the RDS instance which the the database for webapp






