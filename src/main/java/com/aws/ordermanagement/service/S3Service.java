package com.aws.ordermanagement.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.auth.credentials.InstanceProfileCredentialsProvider;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
@Service
public class S3Service {
    private final S3Client s3;

    private final String bucketName;
    public S3Service(  @Value("${cloud.aws.s3.bucket}") String bucketName,   @Value("${cloud.aws.region}") String awsRegion) {
        this.bucketName = bucketName;
        this.s3 = S3Client.builder()
                .region(Region.of(awsRegion)) // match your bucket region
                //.credentialsProvider(ProfileCredentialsProvider.create()) /*Used  only for local testing */
                .credentialsProvider(InstanceProfileCredentialsProvider.create())
                .build();

    }

    public String uploadFile(MultipartFile file) throws IOException {
        String key = file.getOriginalFilename();

        PutObjectRequest putReq = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                //.acl("public-read") // allow file to be accessible via URL
                .build();

        s3.putObject(putReq, RequestBody.fromBytes(file.getBytes()));
        return "https://" + bucketName + ".s3.amazonaws.com/" + key;
    }

}
