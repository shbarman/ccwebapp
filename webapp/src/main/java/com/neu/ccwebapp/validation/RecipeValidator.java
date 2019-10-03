package com.neu.ccwebapp.validation;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.service.RecipeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.Errors;
import org.springframework.validation.ValidationUtils;
import org.springframework.validation.Validator;

public class RecipeValidator implements Validator {

    @Autowired
    private RecipeService recipeService;

    @Override
    public boolean supports(Class<?> aClass) {
        return Recipe.class.isAssignableFrom(aClass);
    }

    @Override
    public void validate(Object obj, Errors errors) {
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "cook_time_in_min", "cook_time_in_min required");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "prep_time_in_min", "prep_time_in_min required");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "title", "title required");
        ValidationUtils.rejectIfEmptyOrWhitespace(errors, "cuisine", "cuisine required");
        if(errors.hasErrors()) return;

        Recipe recipe = (Recipe) obj;

        if(((recipe.getCook_time_in_min())%5 != 0)){
            errors.rejectValue("cook_time_in_min", "Cook Time should be a multiple of 5");
        }
        if((recipe.getPrep_time_in_min() % 5 != 0)){
            errors.rejectValue("prep_time_in_min", "Prep Time should be a multiple of 5");
        }

        if(errors.hasErrors()) return;
    }

}

