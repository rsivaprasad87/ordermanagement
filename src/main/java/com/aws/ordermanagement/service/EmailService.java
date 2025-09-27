package com.aws.ordermanagement.service;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.InstanceProfileCredentialsProvider;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.*;

@Service
@Slf4j
public class EmailService {
    private final SesClient sesClient;

    private final String senderEmail;

    public EmailService(@Value("${cloud.aws.ses.senderEmail}") String senderEmail, @Value("${cloud.aws.region}") String awsRegion) {
        this.senderEmail = senderEmail;
        this.sesClient = SesClient.builder()
                .region(Region.of(awsRegion))
                //.credentialsProvider(ProfileCredentialsProvider.create()) /*Used  only for local testing */
                .credentialsProvider(InstanceProfileCredentialsProvider.create())
                .build();
    }

    public void sendEmail(String to, String subject, String body) {
        Destination destination = Destination.builder().toAddresses(to).build();

        Content content = Content.builder().data(body).build();
        Message message = Message.builder()
                .subject(Content.builder().data(subject).build())
                .body(Body.builder().text(content).build())
                .build();

        SendEmailRequest request = SendEmailRequest.builder()
                .source(senderEmail)  // must be a verified SES sender
                .destination(destination)
                .message(message)
                .build();

        sesClient.sendEmail(request);
        log.info("Email successfully  sent to  {} ",destination);
    }
}
