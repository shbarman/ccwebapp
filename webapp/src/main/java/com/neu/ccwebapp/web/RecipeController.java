package com.neu.ccwebapp.web;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.RecipeCreationErrors;
import com.neu.ccwebapp.exceptions.RecipeDoesNotExistException;
import com.neu.ccwebapp.repository.RecipeRepository;
import com.neu.ccwebapp.repository.UserRepository;
import com.neu.ccwebapp.service.RecipeService;
import com.neu.ccwebapp.validation.RecipeValidator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.BindingResult;
import org.springframework.validation.Validator;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.security.Principal;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/")
public class RecipeController {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private RecipeValidator recipeValidator;

    @Autowired
    UserRepository userRepository;


    @InitBinder
    private void initBinder(WebDataBinder binder) {
        binder.setValidator(recipeValidator);
    }


    @RequestMapping(value = "/v1/recipie", method = RequestMethod.POST)
    public ResponseEntity<?> addRecipe(Principal principal, @Valid @RequestBody Recipe recipe, BindingResult errors,
                                       HttpServletResponse response) throws Exception {
        RecipeCreationErrors recipeCreationErrors;
        String username = principal.getName();

        if (errors.hasErrors()) {
            recipeCreationErrors = recipeService.getRecipieCreationErrors(errors);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
                    recipeCreationErrors);
        } else {
            User u = userRepository.findByUsername(username);
            if (u == null) {
                throw new UsernameNotFoundException("No user found with the username : " + u);
            } else {
                recipe.setCreated_ts();
                recipe.setUpdated_ts();
                recipe.setTotal_time_in_min();
                recipe.setAuthorid(u.getUserID());
                Recipe newrecipe = recipeService.AddRecipe(recipe);
                return new ResponseEntity<Recipe>(newrecipe, HttpStatus.CREATED);
            }
        }
    }


    @RequestMapping(value = "/v1/recipie/{id}", method = RequestMethod.GET)
    public ResponseEntity<?> getRecipePerAuthorId(@PathVariable UUID id) {


        if (recipeService.findById(id).isPresent()) {

            Optional<Recipe> recipe = recipeService.findById(id);

            return ResponseEntity.status(HttpStatus.OK).body(recipe);
        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
        }

    }

    @RequestMapping(method = RequestMethod.PUT, value = "/v1/recipie/{id}") //Put request
    public ResponseEntity<?> updateUser(Principal principal, @Valid @RequestBody Recipe recipe, BindingResult errors, @PathVariable UUID id) throws RecipeDoesNotExistException {

        String name = principal.getName();
        User u = userRepository.findByUsername(name);
        if (u == null) {
            throw new UsernameNotFoundException("No user found with the username : " + u);
        }

        if (recipeService.findById(id).isPresent()) {

            Optional<Recipe> recipefound = recipeService.findById(id);
            UUID rec = recipefound.get().getAuthorid();
            if (rec.equals(u.getUserID())) {
                System.out.println("Equal");
                recipeService.updateRecipe(recipefound.get(), recipe);
                return ResponseEntity.status(HttpStatus.OK).body(recipefound);
            } else
                return new ResponseEntity<Recipe>(HttpStatus.UNAUTHORIZED);

        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
        }


}

    @RequestMapping(value = "/v1/recipie/{id}", method = RequestMethod.DELETE)
    public ResponseEntity<?> deleteRecipeByAuthorId( @PathVariable UUID id,Principal principal) {
        String username = principal.getName();
        User userLoggedIn = userRepository.findByUsername(username);

        if (recipeService.findById(id).isPresent()) {

            Optional<Recipe> recipe = recipeService.findById(id);

            if (userLoggedIn.getUserID().equals(recipe.get().getAuthorid())) {
                recipeService.deleteByRecipesAuthorId(recipe.get().getRecipeId());
                return ResponseEntity.status(HttpStatus.NO_CONTENT).body("");
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("");

            }
        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");

        }
    }


}
