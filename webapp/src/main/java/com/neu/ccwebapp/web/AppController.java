package com.neu.ccwebapp.web;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import javax.validation.Valid;
import java.util.List;
import java.util.UUID;

@RestController
public class AppController {
    @Autowired
    private UserService userService;



    @PostMapping("/v1/user")
    public void registerUser(@Valid @RequestBody User user) {
        try
        {
            userService.registerUser(user);
        }
        catch (UserExistsException e)
        {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,e.getMessage(),e);
        }
    }

}
