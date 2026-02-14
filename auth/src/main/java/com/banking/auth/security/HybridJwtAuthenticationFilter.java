package com.banking.auth.security;

import com.banking.auth.service.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Hybrid JWT Authentication Filter that supports both standard and Post-Quantum
 * JWT tokens.
 * Automatically detects which provider to use based on configuration.
 */
@Component
public class HybridJwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private PQJwtTokenProvider pqJwtTokenProvider;

    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    @Value("${jwt.use-post-quantum:false}")
    private boolean usePostQuantum;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);

            if (StringUtils.hasText(jwt)) {
                String username;
                boolean isValid;

                // Try to validate with the configured provider
                if (usePostQuantum) {
                    isValid = pqJwtTokenProvider.validateToken(jwt);
                    username = isValid ? pqJwtTokenProvider.getUsernameFromToken(jwt) : null;
                } else {
                    isValid = jwtTokenProvider.validateToken(jwt);
                    username = isValid ? jwtTokenProvider.getUsernameFromToken(jwt) : null;
                }

                if (isValid && username != null) {
                    UserDetails userDetails = userDetailsService.loadUserByUsername(username);
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
