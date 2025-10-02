package com.aws.ordermanagement.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {
    private static final String API_DESCRIPTION = "AWS Services With Spring Boot";
    private static final Contact TEAM = new Contact().name("AWS");
    @Bean
    public OpenAPI awsServiceOpenApi() {
        return new OpenAPI().info(new Info().title("AWS Services")
                .description(API_DESCRIPTION)
                .version("1.0")
                .contact(TEAM));
    }
}
