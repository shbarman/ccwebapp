package com.neu.ccwebapp.web;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.service.UserService;
import com.timgroup.statsd.StatsDClient;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.slf4j.LoggerFactory;
import org.slf4j.Logger;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.security.Principal;
import java.util.Date;


@RestController
public class AppController {

    @Autowired
    private UserService userService;

    @Autowired
    private StatsDClient statsDClient;

    private final static Logger logger = LoggerFactory.getLogger(AppController.class);


    @RequestMapping("/v1/user/self") //get request
    public User getUser(Principal principal){

        statsDClient.incrementCounter("v1.user.self.api.get");

            String name = principal.getName();
            System.out.println("name is" + name);

        long startTime =  System.currentTimeMillis();

           User   getuser=userService.loadUsername(name);

        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);
        statsDClient.recordExecutionTime("GetUserAPITime",duration);

        logger.info("Time to retrieve User"+duration);
            return getuser;


    }

    @RequestMapping(method = RequestMethod.PUT, value = "/v1/user/self") //Put request
    public ResponseEntity updateUser(Principal principal, @RequestBody User user) {

        statsDClient.incrementCounter("v1.user.self.api.put");
        String name = principal.getName();

        try {
            long startTime =  System.currentTimeMillis();

            userService.updateUser( name, user);

            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);
            statsDClient.recordExecutionTime("UpdateUserAPITime",duration);

            logger.info("Time to update User"+duration);

            return ResponseEntity.status(HttpStatus.NO_CONTENT).body(" ");
        } catch (UserExistsException e) {
            logger.error("User already exists"+ e.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);

        }
    }



    @PostMapping("/v1/user")
    public ResponseEntity registerUser(@Valid @RequestBody User user) {
        statsDClient.incrementCounter("endpoint.v1.user.api.post");
        try
        {
            long startTime =  System.currentTimeMillis();

            User newUser=userService.registerUser(user);
            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);
            statsDClient.recordExecutionTime("AddUserAPITime",duration);

            logger.info("Time to Add User"+duration);

            return  ResponseEntity.status(HttpStatus.CREATED).body(newUser);

            //return ResponseEntity.status(HttpStatus.CREATED).body(userService.registerUser(user));
        }
        catch (UserExistsException e)

        {
            logger.error("User already exists"+ e.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,e.getMessage(),e);
        }
    }

}
