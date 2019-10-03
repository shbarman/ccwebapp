package com.neu.ccwebapp.exceptions;

public class RecipeDoesNotExistException extends Exception
{
    public RecipeDoesNotExistException(String errorMessage)
    {
        super(errorMessage);
    }
}
