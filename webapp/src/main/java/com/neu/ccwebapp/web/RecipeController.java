package com.neu.ccwebapp.web;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.RecipeImage;
import com.neu.ccwebapp.domain.User;
import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.services.sns.AmazonSNS;
import com.amazonaws.services.sns.AmazonSNSClientBuilder;
import com.amazonaws.services.sns.model.PublishRequest;
import com.neu.ccwebapp.exceptions.RecipeCreationErrors;
import com.neu.ccwebapp.exceptions.RecipeDoesNotExistException;
import com.neu.ccwebapp.repository.RecipeImgRepository;
import com.neu.ccwebapp.repository.UserRepository;
import com.neu.ccwebapp.service.RecipeImgService;
import com.neu.ccwebapp.service.RecipeService;
import com.neu.ccwebapp.validation.RecipeValidator;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.*;
import com.timgroup.statsd.StatsDClient;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.security.Principal;
import java.util.List;
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

    @Autowired
    RecipeImgRepository recipeImgRepository;

    @Autowired
    RecipeImgService recipeImgService;

    @Autowired
    private StatsDClient statsDClient;


    private final static Logger logger = LoggerFactory.getLogger(RecipeController.class);

    @InitBinder
    private void initBinder(WebDataBinder binder) {
        binder.setValidator(recipeValidator);
    }


    @RequestMapping(value = "/v1/recipie", method = RequestMethod.POST)
    public ResponseEntity<?> addRecipe(Principal principal, @Valid @RequestBody Recipe recipe, BindingResult errors,
                                       HttpServletResponse response) throws Exception {


        statsDClient.incrementCounter("endpoint.v1.recipie.api.post");
        RecipeCreationErrors recipeCreationErrors;
        String username = principal.getName();

        if (errors.hasErrors()) {
            recipeCreationErrors = recipeService.getRecipieCreationErrors(errors);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(
                    recipeCreationErrors);
        } else {
            User u = userRepository.findByUsername(username);
            if (u == null) {
                logger.error("No user found with the username : " + u);
                throw new UsernameNotFoundException("No user found with the username : " + u);
            } else {
                recipe.setCreated_ts();
                recipe.setUpdated_ts();
                recipe.setTotal_time_in_min();
                recipe.setAuthorid(u.getUserID());
                long startTime = System.currentTimeMillis();

                Recipe newrecipe = recipeService.AddRecipe(recipe);

                long endTime = System.currentTimeMillis();

                long duration = (endTime - startTime);
                statsDClient.recordExecutionTime("AddRecipeAPITime", duration);

                logger.info("Time to Add Recipe" + duration);

                return new ResponseEntity<Recipe>(newrecipe, HttpStatus.CREATED);
            }
        }
    }


    @RequestMapping(value = "/v1/recipie/{id}", method = RequestMethod.GET)
    public ResponseEntity<?> getRecipePerAuthorId(@PathVariable UUID id) {


        statsDClient.incrementCounter("endpoint.v1.recipie.id.api.get");

        if (recipeService.findById(id).isPresent()) {
            long startTime = System.currentTimeMillis();

            Optional<Recipe> recipe = recipeService.findById(id);

            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);
            statsDClient.recordExecutionTime("GetRecipeAPITime", duration);

            logger.info("Time to Get Recipe" + duration);


            return ResponseEntity.status(HttpStatus.OK).body(recipe);
        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
        }

    }

    @RequestMapping(method = RequestMethod.PUT, value = "/v1/recipie/{id}") //Put request
    public ResponseEntity<?> updateUser(Principal principal, @Valid @RequestBody Recipe recipe, BindingResult errors, @PathVariable UUID id) throws RecipeDoesNotExistException {

        statsDClient.incrementCounter("endpoint.v1.recipie.id.api.put");

        String name = principal.getName();
        User u = userRepository.findByUsername(name);
        if (u == null) {
            logger.error("No user found with the username : " + u);
            throw new UsernameNotFoundException("No user found with the username : " + u);
        }

        if (recipeService.findById(id).isPresent()) {

            Optional<Recipe> recipefound = recipeService.findById(id);

            UUID rec = recipefound.get().getAuthorid();
            if (rec.equals(u.getUserID())) {
                System.out.println("Equal");

                long startTime = System.currentTimeMillis();

                recipeService.updateRecipe(recipefound.get(), recipe);

                long endTime = System.currentTimeMillis();

                long duration = (endTime - startTime);
                statsDClient.recordExecutionTime("UpdateRecipeAPITime", duration);

                logger.info("Time to Update Recipe" + duration);


                return ResponseEntity.status(HttpStatus.OK).body(recipefound);
            } else
                return new ResponseEntity<Recipe>(HttpStatus.UNAUTHORIZED);

        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
        }


    }

    @RequestMapping(value = "/v1/recipie/{id}", method = RequestMethod.DELETE)
    public ResponseEntity<?> deleteRecipeByAuthorId(@PathVariable UUID id, Principal principal) throws Exception {

        statsDClient.incrementCounter("endpoint.v1.recipie.id.api.delete");

        String username = principal.getName();
        User userLoggedIn = userRepository.findByUsername(username);
        logger.info("Deleting recipe");
        if (recipeService.findById(id).isPresent()) {

            Optional<Recipe> recipe = recipeService.findById(id);

            if (userLoggedIn.getUserID().equals(recipe.get().getAuthorid())) {

                if (recipe.get().getImage() != null) {

                    UUID recipeImageID = recipe.get().getImage().getId();
                    Optional<RecipeImage> recipeImage = recipeImgRepository.findById(recipeImageID);
                    recipeImgService.deleteImage(recipeImage, recipe.get().getRecipeId());
                }


                long startTime = System.currentTimeMillis();


                recipeService.deleteByRecipesAuthorId(recipe.get().getRecipeId());

                long endTime = System.currentTimeMillis();

                long duration = (endTime - startTime);
                statsDClient.recordExecutionTime("DeleteRecipeAPITime", duration);

                logger.info("Time to Delete Recipe" + duration);

                return ResponseEntity.status(HttpStatus.NO_CONTENT).body("");
            } else {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("");

            }
        } else {

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");

        }
    }

    @RequestMapping(value = "/v1/myrecipies", method = RequestMethod.POST)
    public ResponseEntity<?> getAllRecipes(Principal principal) throws Exception {

        statsDClient.incrementCounter("endpoint.v1.myrecipies.api.get");

        String name = principal.getName();
        User u = userRepository.findByUsername(name);
        if (u == null) {
            logger.error("No user found with the username : " + u);
            throw new UsernameNotFoundException("No user found with the username : " + u);
        }

        UUID authorId = u.getUserID();
        JSONArray jsonArray = new JSONArray();
        JSONObject jsonObj = new JSONObject();
        jsonObj.put("UserEmailAddress",name);

        List<Recipe> allRecipes = recipeService.getAllRecipes(authorId);
        for (int i = 0; i < allRecipes.size(); i++) {

            jsonArray.add(allRecipes.get(i).getRecipeId() ); // the value can also be a json object or a json array

            logger.info("entries: " + allRecipes.get(i).getRecipeId());
        }

        jsonObj.put("RecipeID",jsonArray);

        System.out.println("the recipeID "+ jsonObj.get("RecipeID"));
        System.out.println("the email address "+ jsonObj.get("UserEmailAddress"));


            AmazonSNS sns = AmazonSNSClientBuilder.standard().build();

            String topic = sns.createTopic("EmailNotificationRecipeEndpoint").getTopicArn();
            logger.info(topic);
            PublishRequest pubRequest = new PublishRequest(topic, jsonObj.toString());
            sns.publish(pubRequest);


        return ResponseEntity.status(HttpStatus.NO_CONTENT).body("");
    }

    @RequestMapping(value= "/recipes", method = RequestMethod.GET)
    public ResponseEntity<?> getLatestRecipe()  {
        statsDClient.incrementCounter("endpoint.v1.recipes.api.get");
        long startTime = System.currentTimeMillis();
        Recipe recipe = null;
        if(recipeService.getLatestRecipie()!=null){
            recipe = recipeService.getLatestRecipie();
            logger.info("Latest Recipe fetch successful");
            long endTime = System.currentTimeMillis();
            long duration = (endTime - startTime);
            statsDClient.recordExecutionTime("getRecipieTime", duration);
            return new ResponseEntity<Recipe>(recipe, HttpStatus.OK);
        }
        logger.error("Recipe fetch failed. Recipe not found");
        long endTime = System.currentTimeMillis();
        long duration = (endTime - startTime);
        statsDClient.recordExecutionTime("getRecipieTime", duration);
        return new ResponseEntity<>(null, HttpStatus.NOT_FOUND);
    }

}