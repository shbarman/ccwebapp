package com.neu.ccwebapp.exceptions;

public class UserExistsException extends Exception
{
    public UserExistsException(String errorMessage)
    {
        super(errorMessage);
    }
}
