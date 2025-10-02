package com.aws.ordermanagement.listener;

import com.aws.ordermanagement.model.Customer;
import com.aws.ordermanagement.service.EmailService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.InstanceProfileCredentialsProvider;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import java.util.List;

@Service
@Slf4j
public class SqsListenerService {


    private SqsClient sqsClient;

    private final EmailService emailService;
    private final String awsRegion;
    private final String queueUrl;
    @Autowired
    public SqsListenerService(EmailService emailService, @Value("${cloud.aws.region}") String awsRegion, @Value("${cloud.aws.sqs.queueUrl}") String queueUrl) {
        this.queueUrl = queueUrl;
        this.emailService = emailService;
        this.awsRegion = awsRegion;
    }

    @PostConstruct
    public void init() {
        sqsClient = SqsClient.builder()
                .region(Region.of(awsRegion))
                //.credentialsProvider(ProfileCredentialsProvider.create()) /*Used  only for local testing */
                .credentialsProvider(InstanceProfileCredentialsProvider.create())
                .build();
    }

    public void pollSqsMessages(Customer customer) {
        try {
            ReceiveMessageRequest request = ReceiveMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .maxNumberOfMessages(5)
                    .waitTimeSeconds(10)
                    .build();

            List<Message> messages = sqsClient.receiveMessage(request).messages();

            for (Message message : messages) {
                log.info("Received message: {}", message.body());

                // TODO: Parse the JSON and link to customer if needed
                ObjectMapper mapper = new ObjectMapper();
                JsonNode jsonNode = mapper.readTree(message.body());
                String fileName = jsonNode.get("file").asText();
                log.info("File uploaded to S3: {}", fileName);

                //Send Email to customer
                log.info("Sending email to customer : {} ",customer.getEmail());
                try {
                    emailService.sendEmail(
                            customer.getEmail(),
                            "Document Uploaded",
                            "Hi " + customer.getName() + ", your document " + fileName + " was uploaded successfully."
                    );
                    // Delete the message after processing
                    sqsClient.deleteMessage(DeleteMessageRequest.builder()
                            .queueUrl(queueUrl)
                            .receiptHandle(message.receiptHandle())
                            .build());
                }
                catch (Exception e) {
                    log.error("Error in sending email to {} ", customer.getEmail());
                }
            }
        } catch (Exception e) {
            log.error("SQS polling error: {}", e.getMessage());
        }
    }
}
