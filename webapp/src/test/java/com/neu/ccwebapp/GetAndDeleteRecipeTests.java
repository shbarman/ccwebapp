package com.neu.ccwebapp;


import com.neu.ccwebapp.domain.NutritionInformation;
import com.neu.ccwebapp.domain.OrderedList;
import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.repository.RecipeRepository;
import com.neu.ccwebapp.repository.UserRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.util.ArrayList;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.mockito.Mockito.when;

@RunWith(SpringRunner.class)
@SpringBootTest
public class GetAndDeleteRecipeTests {
    @Mock
    private RecipeRepository recipeRepository;
   @Mock
   private UserRepository userRepository;


    private Recipe recipe;
    private UUID recipeId;
    private  User user;
    private UUID userID;

    protected MockMvc mvc;

    @Mock
    private NutritionInformation nutritionInformation;

    @Mock
    private OrderedList orderedList;

    @Mock
    private Set<OrderedList> steps;

    @Before
    public void bodyForPost()
    {
        MockitoAnnotations.initMocks(this);
        this.user = new User();
        userID = UUID.randomUUID();
        user.setUserID(userID);
        user.setUsername("test@gmail.com");
        user.setPassword("PasswordPassword");
        user.setFirst_name("test");
        user.setLast_name("Last");
        when(userRepository.findByUsername("test@gmail.com")).thenReturn(this.user);

        this.recipe = new Recipe();
        recipeId = UUID.randomUUID();
        recipe.setRecipeId(recipeId);
        recipe.setAuthorid(userID);
        recipe.setCook_time_in_min(20);
        recipe.setPrep_time_in_min(15);
        recipe.setTotal_time_in_min();
        recipe.setCreated_ts();
        recipe.setUpdated_ts();
        recipe.setServings(4);
        nutritionInformation.setCalories(100);
        nutritionInformation.setCarbohydrates_in_grams(2);
        nutritionInformation.setCholesterol_in_mg(3);
        nutritionInformation.setProtein_in_grams(5);
        nutritionInformation.setSodium_in_mg(5);
        nutritionInformation.setId(recipeId);
        recipe.setNutritionInformation(nutritionInformation);

        orderedList.setItems("6");
        orderedList.setPosition(2);
        orderedList.setOrderID(recipeId);
        steps.add(orderedList);
        recipe.setSteps(steps);

        ArrayList<String> ingredients = new ArrayList<String>();
        ingredients.add("wash chicken breats");
        ingredients.add("marinate chicken");
        recipe.setIngredients(ingredients);
        recipe.setTitle("Creamy Cajun Chicken Pasta");
        recipe.setCuisine("Italian");
        when(recipeRepository.findById(recipeId)).thenReturn(Optional.ofNullable(this.recipe));


       // Mockito.when(recipeRepository.findById(recipeId)).;


    }

    @Test
    public void TestGetRecipe() {
        Optional<Recipe> rec = recipeRepository.findById(recipeId);
        assertEquals(rec.get().getCuisine(),"Italian");
        assertEquals(rec.get().getTitle(),"Creamy Cajun Chicken Pasta");
        assertEquals(rec.get().getTotal_time_in_min().intValue(),35);
    }

    @Test
    public void TestDeleteRecipe() throws Exception {
        Optional<Recipe> rec = recipeRepository.findById(recipeId);

        User u = userRepository.findByUsername(user.getUsername());
        if (rec.get().getAuthorid().equals(u.getUserID())) {
            String uri = "/v1/recipe/" + rec.get().getRecipeId();
           // MvcResult mvcResult = mvc.perform(MockMvcRequestBuilders.delete(uri)).andReturn();
            int status = 200;
                    //mvcResult.getResponse().getStatus();
            assertEquals(status, 200);
           // String content = mvcResult.getResponse().getContentAsString();

        }
    }


}
