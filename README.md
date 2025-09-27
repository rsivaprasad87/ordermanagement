# Spring Boot + AWS Order Management Project

This project demonstrates how to build and deploy a **Spring Boot Order Management Application** integrated with multiple **AWS services**. It is designed as a step-by-step beginner-friendly learning project.

---

## AWS Services Used
1. **Amazon RDS (MySQL)** – Persistent relational database for customer records.  
2. **Amazon S3** – Store uploaded customer documents/files.  
3. **Amazon SQS** – Queue for decoupled communication after file uploads.  
4. **Amazon SES** – Send email notifications to customers.  
5. **AWS Lambda** – Event-driven function to push file-upload events into SQS.  
6. **Elastic Beanstalk** – Deployment platform (with single EC2 instance free tier).  
7. **IAM Roles & Policies** – Secure access for S3, SQS, SES, RDS.  

---

## Running the Project Locally

### 1. Prerequisites
- Java 17+  
- Maven or Gradle  
- AWS CLI configured (`aws configure`) with an IAM user having access to S3, RDS, SQS, SES
- Terraform installed  
- All the AWS resources S3, RDS, SQS, SES & Elastic Beanstalk can be created using the terraform code available with the project (recommended)
- 
### 2. Clone Repository
```bash
git clone https://github.com/rsivaprasad87/ordermanagement.git
cd ordermanagement
```

### 3. Build and Run
```bash
mvn clean install
mvn spring-boot:run

Note: Build the project and once the jar is avaialble , the values for the environment varibales to run the project can be 
found only fater the AWS resources were created  using terraform (Refer step 4)

Once the envrionemnt variables are avaialble, run the project locally using below steps 
1. Use Postman or the Swagger page: http://localhost:8080/ws-ordermanagement/swagger-ui.html  
2. Create a customer in RDS using the endpoint http://localhost:8080/ws-ordermanagement/createCustomer which will provide a auto generated customer id
3. Upload a file in S3 bucket for the customer id using endpoint http://localhost:8080/ws-ordermanagement/s3bucketstorage/upload/{customerId}
4. Uploading the documents to S3 will provide a document url as response and it triggers a lambda function that sends a message to SQS queue   
5. The document url is for updated for the customer in RDS   
6. Message from queue is polled and an email notification is sent to the customer 

```
---
## 4. Terraform Setup

```bash
Open the ordermanagement terraform folder in visual studio code 
Update the variable values for db_name, db_username,db_password, ses_email, aws_region
From terminal , execute the below commands
terraform init
terraform plan
Add the jar file of the project to the terraform folder as a zip file and run the command "terraform apply -auto-approve"
This will create all AWS required resources and deploy the project jar into Elastic Beanstalk environment
After Terraform finishes, All the required enviornment variables can be found using command "terraform output"
```

### 5. Configure the environment variables in Spring Boot
```
-DDB_URL=jdbc:mysql://<rds-endpoint>:3306/customerdb
-DDB_USERNAME=<db-username>
-DDB_PASSOWRD=<db-password>
-DAWS_REGION=<aws region name>
-DS3_BUCKET_NAME=<your-s3-bucket>
-DQUEUE_URL=<your-sqs-queue-url>
-DSES_SENDER_EMAIL=<your-verified-ses-email>
```


## 6. Destroy 
- **Destroy everything ** (cleanup):
  ```bash
  terraform destroy
  ```
- **Check outputs**:
  ```bash
  terraform output
  ```

---

## 7. Common Errors & Fixes

| Error                                                        | Cause                                                                      | Solution                                                                                                                                                                                                                                                                |
|--------------------------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `No database selected`                                       | JDBC URL missing DB name                                                   | Ensure `ordermanagement` schema is in RDS and JDBC URL includes the database name `/ordermanagement/customerdb`                                                                                                                                                         |
| `Profile file contained no credentials for profile 'default'` | SDK trying to load local AWS profile on EB                                 | Use `InstanceProfileCredentialsProvider` to use IAM role credentials  //.credentialsProvider(ProfileCredentialsProvider.create()) - Used  only for local testing and .credentialsProvider(InstanceProfileCredentialsProvider.create()) to be used for Elastic Beanstalk |
| `AccessDenied: elastic load balancing`                       | EB service role lacks permission                                           | Attach `AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy` to EB role. Also application runs on port 8080. Default port of Load balcner is 80 .So LB should be listen on port 80 and forward request to 8080                                                          |
| `main.hanlder not found`                                     | The Lambda function file zipped into a subdirectory instead of root folder | .zip file of lambda function should be under root directory .Also the  handler name used in terrfaorm code while creating the resource should be the same as it is defined in the lambda function                                                   |

---

## 8. Useful Tips
- https://docs.aws.amazon.com/sdkref/latest/guide/file-location.html --> AWS credentials 
- If you have access to the AWS CLI, you can use the following command to check the access key and secret access key set for a user.
aws configure get aws_access_key_id
aws configure get aws_secret_access_key
- Due to Below config in application.yml  , tables are created automatically in RDS database based on the entity definition when the database connection is established
  jpa:
  hibernate:
  ddl-auto: update
- Once the connection is established use the below commands with RDS 
  Each command should end with semicolon
  show databases;
  use customerdb; <your database name >
  show tables;
  show columns from customer;
  select * from customer;
  Note:
- ** Though RDS is in free tier , the public IP assigned to it  and associated to a VPC incurs a charge **
- ** Though Elastic beanstalk itself is free , use config for only EC2 with single instance , the public IP assigned to it  and associated to a VPC incurs a charge **
---

💡 
