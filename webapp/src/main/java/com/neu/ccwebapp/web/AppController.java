package com.neu.ccwebapp.web;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

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


    @RequestMapping("/v1/user/self") //get request
    public User getUser(Principal principal){

        String name = principal.getName();
        System.out.println("name is"+ name);

        return userService.loadUsername(name);
    }

    @RequestMapping(method = RequestMethod.PUT, value = "/v1/user/self") //Put request
    public ResponseEntity updateUser(Principal principal, @RequestBody User user) {

        String name = principal.getName();

        try {

            userService.updateUser( name, user);
            return ResponseEntity.status(HttpStatus.NO_CONTENT).body(" ");
        } catch (UserExistsException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);


        }
    }



    @PostMapping("/v1/user")
    public ResponseEntity registerUser(@Valid @RequestBody User user) {
        try
        {
            User newUser=userService.registerUser(user);
            return  ResponseEntity.status(HttpStatus.CREATED).body(newUser);

            //return ResponseEntity.status(HttpStatus.CREATED).body(userService.registerUser(user));
        }
        catch (UserExistsException e)
        {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,e.getMessage(),e);
        }
    }

}
