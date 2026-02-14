package com.banking.transaction.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Component
public class FeignClientInterceptor implements RequestInterceptor {

    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_TOKEN_TYPE = "Bearer";

    @Override
    public void apply(RequestTemplate template) {
        // Get the current HTTP request
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();

            // Extract Authorization header from the incoming request
            String authorizationHeader = request.getHeader(AUTHORIZATION_HEADER);

            // Forward the Authorization header to the Feign client request
            if (authorizationHeader != null && authorizationHeader.startsWith(BEARER_TOKEN_TYPE)) {
                template.header(AUTHORIZATION_HEADER, authorizationHeader);
            }
        }
    }
}
