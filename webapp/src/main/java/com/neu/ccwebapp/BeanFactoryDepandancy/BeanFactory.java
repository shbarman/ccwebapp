package com.neu.ccwebapp.BeanFactoryDepandancy;


import com.neu.ccwebapp.validation.RecipeValidator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.web.authentication.www.BasicAuthenticationEntryPoint;
import org.springframework.security.core.AuthenticationException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Configuration
public class BeanFactory {

    @Bean
    public BasicAuthenticationEntryPoint basicAuthenticationEntryPoint(){
        return new BasicAuthenticationEntryPoint() {
            @Override
            public void afterPropertiesSet() throws Exception {
                setRealmName("Recipe_management_system");
                super.afterPropertiesSet();
            }


            @Override
            public void commence(HttpServletRequest request,
                                 HttpServletResponse response,
                                 AuthenticationException authException) throws IOException {
                response.addHeader("WWW-Authenticate", "Basic realm = "+getRealmName());
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().println("Access denied");
            }
        };
    }
}
