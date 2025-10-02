package com.aws.ordermanagement.controller;

import com.aws.ordermanagement.model.Customer;
import com.aws.ordermanagement.service.CustomerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class CustomerController {
    private final CustomerService service;

    public CustomerController(CustomerService service) {
        this.service = service;
    }

    @GetMapping("/getAllCustomers")
    public List<Customer> getAll() {
        return service.getAllCustomers();
    }

    @PostMapping("/createCustomer")
    public Customer create(@RequestBody Customer customer) {
        return service.addCustomer(customer);
    }

    @GetMapping("/getCustomer/{id}")
    public ResponseEntity<Customer> getById(@PathVariable Long id) {
        return service.getCustomerById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("deleteCustomer/{id}")
    public void delete(@PathVariable Long id) {
        service.deleteCustomer(id);
    }
}
