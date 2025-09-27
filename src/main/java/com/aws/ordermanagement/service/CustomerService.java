package com.aws.ordermanagement.service;

import com.aws.ordermanagement.model.Customer;
import com.aws.ordermanagement.repository.CustomerRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CustomerService {
    private final CustomerRepository repo;

    public CustomerService(CustomerRepository repo) {
        this.repo = repo;
    }

    public List<Customer> getAllCustomers() {
        return repo.findAll();
    }

    public Customer addCustomer(Customer customer) {
        return repo.save(customer);
    }

    public Optional<Customer> getCustomerById(Long id) {
        return repo.findById(id);
    }

    public void deleteCustomer(Long id) {
        repo.deleteById(id);
    }
}
