package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import org.springframework.security.core.userdetails.UserDetails;

public interface
UserService
{
    User registerUser(User user) throws UserExistsException;

    void updateUser(String name, User user) throws UserExistsException;

    public User loadUsername(String userName);

    public UserDetails loadUserByUsername(String username);
    
}
