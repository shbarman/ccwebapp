package com.neu.ccwebapp.web;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.RecipeImage;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.repository.RecipeImgRepository;
import com.neu.ccwebapp.repository.RecipeRepository;
import com.neu.ccwebapp.repository.UserRepository;
import com.neu.ccwebapp.service.RecipeImgService;
import com.neu.ccwebapp.service.RecipeService;

import com.timgroup.statsd.StatsDClient;
import org.slf4j.Logger;
        import org.slf4j.LoggerFactory;
        import org.springframework.beans.factory.annotation.Autowired;
        import org.springframework.http.HttpStatus;
        import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.annotation.Validated;
        import org.springframework.web.bind.annotation.*;
        import org.springframework.web.multipart.MultipartFile;

        import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.security.Principal;
import java.util.Optional;
import java.util.UUID;

@RestController

@Validated
public class RecipeImageController {

    private static final Logger LOGGER = LoggerFactory.getLogger(RecipeImageController.class);

//    @Autowired
//    private StatsDClient metricsClient;

    @Autowired
    private RecipeService recipeService;


    @Autowired
    RecipeImgService recipeImgService;


    @Autowired
    RecipeRepository recipeRepository;

    @Autowired
    RecipeImgRepository recipeImgRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    private StatsDClient statsDClient;

    private final static Logger logger = LoggerFactory.getLogger(RecipeImageController.class);



    @RequestMapping(method = RequestMethod.POST, value = "/v1/recipie/{idRecipe}/image")
    public ResponseEntity<?> addRecipeImage(Principal principal,@PathVariable UUID idRecipe, @RequestParam MultipartFile image, HttpServletRequest request) throws Exception {



        statsDClient.incrementCounter("endpoint.v1.recipie.idRecipe.image.api.post");

        String name = principal.getName();
        User u = userRepository.findByUsername(name);
        if (u == null) {
            throw new UsernameNotFoundException("No user found with the username : " + u);
        }
        else {

            System.out.println("image is " + image);
            if (!recipeImgService.isImagePresent(image))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{ \"error\": \"Select a file\" }");
            if (!recipeImgService.isFileFormatRight(image.getContentType()))
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{ \"error\": \"Image File Format Wrong\" }");

            Optional<Recipe> recipe = recipeService.findById(idRecipe);

            if (recipe.isEmpty()) {

                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{ \"error\": \"Recipe not Found\" }");

            }
          else {

                UUID rec = recipe.get().getAuthorid();
                if (rec.equals(u.getUserID())) {

            if (recipeService.isRecipeImagePresent(recipe)) {
                LOGGER.warn("POST->Cover exist already perform PUT to modify");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("{ \"error\": \"POST->Recipe Image exist already perform PUT to modify\" }");
            }



                    RecipeImage recipeImage = new RecipeImage();
                    //   String photoNewName =  generateFileName(file);

                    String photoNewName = recipe.get().getRecipeId()+"/"+image.getOriginalFilename();

                    long startTime =  System.currentTimeMillis();

                    recipeImage = recipeImgService.uploadImage(image, photoNewName,recipeImage );


                    recipe.get().setImage(recipeImage);

                    recipeRepository.save(recipe.get());

                    long endTime = System.currentTimeMillis();

                    long duration = (endTime - startTime);
                    statsDClient.recordExecutionTime("AddRecipeImageAPITime",duration);

                    logger.info("Time to Add Recipe Image"+duration);



                    return ResponseEntity.status(HttpStatus.OK).body(recipeImage);

                }

                else {

                    return new ResponseEntity<Recipe>(HttpStatus.UNAUTHORIZED);
                }

                }


        }


    }


    @DeleteMapping("/v1/recipie/{idRecipe}/image/{idImage}")
    public ResponseEntity<?> deleteImage(Principal principal,@PathVariable UUID idRecipe, @PathVariable UUID idImage) throws Exception {

        statsDClient.incrementCounter("endpoint.v1.recipie.idRecipe.image.idImage.api.delete");

        String name = principal.getName();
        User u = userRepository.findByUsername(name);
        if (u == null) {
            throw new UsernameNotFoundException("No user found with the username : " + u);
        }
        else {


            Optional<Recipe> recipe = recipeService.findById(idRecipe);

            System.out.println("rec is" + recipe.get().getTitle());

            if (recipe.isEmpty()) {

                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
            }
            else{
                UUID rec = recipe.get().getAuthorid();
                if (rec.equals(u.getUserID())) {

                    Optional<RecipeImage> recipeImage = recipeImgRepository.findById(idImage);


                    if (recipeImage.isEmpty()) {

                        return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");


                    }
                            else {

                        if (recipe.get().getImage().getId().equals(idImage)) {

                            long startTime =  System.currentTimeMillis();

                            recipeImgService.deleteImage(recipeImage,recipe.get().getRecipeId());

                            recipe.get().setImage(null);


                            recipeImgRepository.delete(recipeImage.get());

                            long endTime = System.currentTimeMillis();

                            long duration = (endTime - startTime);
                            statsDClient.recordExecutionTime("DeleteRecipeImageAPITime",duration);

                            logger.info("Time to Delete Recipe Image"+duration);



                            return ResponseEntity.status(HttpStatus.NO_CONTENT).body("");

                        } else {

                            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
                        }


                    }
                } else {

                    return new ResponseEntity<Recipe>(HttpStatus.UNAUTHORIZED);
                }

            }
        }



    }


    @GetMapping("/v1/recipie/{idRecipe}/image/{idImage}")
    public ResponseEntity<?> getImage(@PathVariable UUID idRecipe, @PathVariable UUID idImage) throws Exception {

        statsDClient.incrementCounter("endpoint,v1.recipie.idRecipe.image.idImage.api.get");

        Optional<Recipe> recipe = recipeService.findById(idRecipe);


        if (recipe.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
        } else {

            long startTime =  System.currentTimeMillis();

            Optional<RecipeImage> recipeImage = recipeImgRepository.findById(idImage);

            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);
            statsDClient.recordExecutionTime("GetRecipeImageAPITime",duration);

            logger.info("Time to Get Recipe Image"+duration);




            if (recipeImage.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
            } else {

                if (recipe.get().getImage().getId().equals(idImage)) {

                    return ResponseEntity.status(HttpStatus.OK).body(recipeImage);
                } else {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND).body("");
                }

            }
        }

    }


    }




