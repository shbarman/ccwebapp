package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;

public interface UserService
{
    void registerUser(User user) throws UserExistsException;

    void updateUser(String name, User user) throws UserExistsException;

    public User loadUsername(String userName);
    
}
