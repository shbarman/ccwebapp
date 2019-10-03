package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.exceptions.RecipeCreationErrors;
import com.neu.ccwebapp.exceptions.RecipeDoesNotExistException;
import com.neu.ccwebapp.repository.RecipeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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

    public void deleteByRecipesAuthorId(UUID recipeAuthorId)
    {
        Recipe toBeDeletedRecipe = recipeRepository.getOne(recipeAuthorId);
        recipeRepository.delete(toBeDeletedRecipe);
         ResponseEntity.status(HttpStatus.NO_CONTENT).body("Deleted Recipe");
    }



    public void updateRecipe(Recipe recFound,Recipe recipe) throws RecipeDoesNotExistException {

        recFound.setAuthorid(recFound.getAuthorid());
        recFound.setRecipeId(recFound.getRecipeId());
        recFound.setCook_time_in_min(recipe.getCook_time_in_min());
        recFound.setCuisine(recipe.getCuisine());

        recFound.getIngredients().clear();
        recFound.getIngredients().addAll(recipe.getIngredients());
       // recFound.setIngredients(recipe.getIngredients());

        recFound.setPrep_time_in_min(recipe.getPrep_time_in_min());
        recFound.setTotal_time_in_min();
        recFound.setNutritionInformation(recipe.getNutritionInformation());
        recFound.setServings(recipe.getServings());

        recFound.getSteps().clear();
        recFound.getSteps().addAll(recipe.getSteps());
        //recFound.setSteps(recipe.getSteps());

        recFound.setTitle(recipe.getTitle());
        recipeRepository.saveAndFlush(recFound);
        //recipeRepository.save(recFound);
        }
    }






