package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.exceptions.RecipeCreationErrors;
import com.neu.ccwebapp.repository.RecipeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;

import java.util.Optional;
import java.util.UUID;

@Service
public class RecipeService {


    @Autowired
    RecipeRepository recipeRepository;


    public Recipe AddRecipe(Recipe recipe){
        recipeRepository.save(recipe);
        return recipe;
    }

    public RecipeCreationErrors getRecipieCreationErrors(BindingResult errors) {

        FieldError cookTimeMinError = errors.getFieldError("cook_time_in_min");
        FieldError prepTimeMinError = errors.getFieldError("prep_time_in_min");
        FieldError titleError = errors.getFieldError("title");
        FieldError cuisineError = errors.getFieldError("cuisine");
        String cookTimeErrorMessage = cookTimeMinError == null ? "No error" : cookTimeMinError.getCode();
        String prepTimeErrorMessage = prepTimeMinError == null ? "No error" : prepTimeMinError.getCode();
        String titleErrorMessage = titleError == null ? "No error" : titleError.getCode();
        String cuisineErrorMessage = cuisineError == null ? "No error" : cuisineError.getCode();
        RecipeCreationErrors recipieCreationStatus = new RecipeCreationErrors(cookTimeErrorMessage, prepTimeErrorMessage, titleErrorMessage, cuisineErrorMessage);
        return recipieCreationStatus;
    }



    public Optional<Recipe> findById(UUID id) {

        try{
            return recipeRepository.findById(id);
        }catch(Exception exc) {
            return null;
        }


    }

}




