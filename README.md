# CSYE 6225 - Fall 2019

## Team Information

| Name | NEU ID | Email Address |
| --- | --- | --- |
| Harshitha Somasundar |001497986 | somasundar.h@husky.neu.edu |
| Shuravi Barman | 001475070 | barman.s@husky.neu.edu |
| Bhashmi dineshbai Fatnani |  001449268 |  fatnani.b@husky.neu.edu|
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
1. You can run your application from IDE
2. From terminal you need to run mvn spring-boot:run as maven provides dependency
3. Also from terminal you can run the application by creating it's jar with command $ java -jar target/myapplication-0.0.1-SNAPSHOT.jar


## Deploy Instructions
1. To run our API's we have used Postman.
2. You can run get delete post and put apis
3. For basic authenction enable authorization hit update request it will be added to headers.



## Running Tests
1. Tests are on Springrunner junit5 class
2. used @Sprinboottest annotations to denote test class 
3. Mocked services to use method like findbyId and findbyUsername
4. Unit test cases for all api's along with integration testing

## CI/CD
1. open path of your ccwebapp in terminal
2. then connect mysql database using mysql -u root -p enter root password you will be connected to mysql database.
3. Select your database use ccwebapp;
4. then you can query to check any table like user or recipe.



