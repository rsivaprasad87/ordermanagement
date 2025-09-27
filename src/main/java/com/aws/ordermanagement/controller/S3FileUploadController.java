package com.aws.ordermanagement.controller;
import com.aws.ordermanagement.listener.SqsListenerService;
import com.aws.ordermanagement.service.CustomerService;
import com.aws.ordermanagement.service.S3Service;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/s3bucketstorage")
@Slf4j
public class S3FileUploadController {
    private final S3Service s3Service;
    private final CustomerService customerService;
    private final SqsListenerService sqsListenerService;

    public S3FileUploadController(S3Service s3Service, CustomerService customerService, SqsListenerService sqsListenerService) {
        this.s3Service = s3Service;
        this.customerService = customerService;
        this.sqsListenerService = sqsListenerService;
    }

    @PostMapping("/upload")
    public ResponseEntity<String> upload(@RequestParam("file") MultipartFile file) {
        /* This end point is used to get experience with  uploading a file to S3 bucket */
        try {
            String url = s3Service.uploadFile(file);
            return ResponseEntity.ok("File uploaded: " + url);
        } catch (Exception e) {
            log.error("Exception while uploading file: {}", e.getMessage());
            return ResponseEntity.status(500).body("Upload failed: " + e.getMessage());
        }
    }

    @PostMapping("/upload/{customerId}")
    public ResponseEntity<String> uploadForCustomer(
            @PathVariable Long customerId,
            @RequestParam("file") MultipartFile file) {

        try {
            String url = s3Service.uploadFile(file);
            //Uploading the document will trigger a lambda function in the backend that send a message to SQS
            // update the customer record
            var customerOpt = customerService.getCustomerById(customerId);
            if (customerOpt.isPresent()) {
                var customer = customerOpt.get();
                customer.setDocumentUrl(url);
                customerService.addCustomer(customer); // save updated customer
                //Read the message from queue
                sqsListenerService.pollSqsMessages(customer);
                return ResponseEntity.ok("Uploaded and associated with customer id "  + customerId + " URL: " + url);
            } else {
                return ResponseEntity.status(404).body("Customer not found");
            }

        } catch (Exception e) {
            log.error("Exception while uploading file: {}", e.getMessage());
            return ResponseEntity.status(500).body("Upload failed: " + e.getMessage());
        }
    }
}
