package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.exceptions.RecipeCreationErrors;
import com.neu.ccwebapp.exceptions.RecipeDoesNotExistException;
import com.neu.ccwebapp.repository.RecipeRepository;
import com.timgroup.statsd.StatsDClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class RecipeService {


    @Autowired
    RecipeRepository recipeRepository;

    @Autowired
    private StatsDClient statsDClient;


    private final static Logger logger = LoggerFactory.getLogger(RecipeService.class);


    public Recipe AddRecipe(Recipe recipe){

        long startTime =  System.currentTimeMillis();

        recipeRepository.save(recipe);
        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);

        statsDClient.recordExecutionTime("dbQueryTimeCreateRecipe",duration);

        logger.info("New Recipe  has been added to the DB");

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
            long startTime =  System.currentTimeMillis();

            Optional<Recipe> recipe=recipeRepository.findById(id);
            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("dbQueryTimeGetRecipe",duration);

            logger.info("Get recipe from DB");

            return recipe;
        }catch(Exception exc) {
            logger.error("Could not find Recipe by Recipe ID");
            return null;
        }


    }

    public List<Recipe> getAllRecipes(UUID id) {

        try{
            long startTime =  System.currentTimeMillis();

            List<Recipe> allRecipes=recipeRepository.findByAuthorid(id);
            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("dbQueryTimeGetAllRecipe",duration);

            logger.info("Get All recipe from DB");

            return allRecipes;
        }catch(Exception exc) {
            logger.error("Could not find Recipes for the given userId");
            return null;
        }


    }

    public void deleteByRecipesAuthorId(UUID recipeAuthorId)
    {
        Recipe toBeDeletedRecipe = recipeRepository.getOne(recipeAuthorId);
        long startTime =  System.currentTimeMillis();

        recipeRepository.delete(toBeDeletedRecipe);
        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);

        statsDClient.recordExecutionTime("dbQueryTimDeleteRecipe",duration);

        logger.info("Recipe has been deleted from the DB");

         ResponseEntity.status(HttpStatus.NO_CONTENT).body("Deleted Recipe");
    }

    public Recipe getLatestRecipie() {
        try{
            long startTime = System.currentTimeMillis();
            Recipe latestRecipe = null;
            if(recipeRepository.findFirstByCreated_ts().get(0)!=null) {
                latestRecipe = recipeRepository.findFirstByCreated_ts().get(0);
            }

            long endTime = System.currentTimeMillis();
            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("dbQueryLatestRecipe",duration);
            logger.info("Get latest recipe from DB");

            return latestRecipe;
        } catch (Exception exc) {
            logger.error("Could not get latest Recipe from the dB");
            return null;
        }
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
        long startTime =  System.currentTimeMillis();

        recipeRepository.saveAndFlush(recFound);
        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);

        statsDClient.recordExecutionTime("dbQueryTimeUpdateRecipe",duration);

        logger.info("Recipe has been updated in the DB");

        //recipeRepository.save(recFound);
        }

    public boolean isRecipeImagePresent(Optional<Recipe> recipe) {
        if(recipe.get().getImage() == null) return false;
        return true;
    }
    }






