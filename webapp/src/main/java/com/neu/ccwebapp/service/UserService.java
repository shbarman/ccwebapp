package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;

public interface UserService
{
    User registerUser(User user) throws UserExistsException;
}
