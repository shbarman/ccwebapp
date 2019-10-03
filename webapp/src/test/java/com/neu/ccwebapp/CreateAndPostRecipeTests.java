package com.neu.ccwebapp;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.repository.RecipeRepository;
import com.neu.ccwebapp.repository.UserRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

@RunWith(SpringRunner.class)
@SpringBootTest
public class CreateAndPostRecipeTests {


    @Mock
    private UserRepository userRepository;
    @Mock
    private RecipeRepository recipeRepository;

    private User user;
    private Recipe recipe;
    private UUID recipeId;
    private UUID userID;


    @Before
    public void bodyForPost()
    {
        MockitoAnnotations.initMocks(this);
        this.user = new User();
        userID = UUID.randomUUID();
        user.setUserID(userID);
        user.setUsername("test@gmail.com");
        user.setPassword("PasswordPassword");
        Mockito.when(userRepository.findByUsername("test@gmail.com")).thenReturn(this.user);

        this.recipe = new Recipe();
        recipeId = UUID.randomUUID();
        recipe.setRecipeId(recipeId);
        recipe.setAuthorid(userID);
        recipe.setCook_time_in_min(20);
        recipe.setPrep_time_in_min(15);
        recipe.setTotal_time_in_min();
        recipe.setServings(4);
        ArrayList<String> ingredients = new ArrayList<String>();
        ingredients.add("wash chicken breats");
        ingredients.add("marinate chicken");
        recipe.setIngredients(ingredients);
        recipe.setTitle("Creamy Cajun Chicken Pasta");
        recipe.setCuisine("Italian");
        Mockito.when(recipeRepository.findById(recipeId)).thenReturn(java.util.Optional.ofNullable(this.recipe));

    }

    @Test
    public void TestPostRecipe() {
        Optional<Recipe> rec = recipeRepository.findById(recipeId);
        assertEquals(rec.get().getAuthorid(),userID);
        assertEquals(rec.get().getCuisine(),"Italian");
        assertEquals(rec.get().getTotal_time_in_min().intValue(),35);
    }

    @Test
    public void TestPutRecipe() {
        Optional<Recipe> rec = recipeRepository.findById(recipeId);
        rec.get().setCuisine("indian");
        recipe.setCook_time_in_min(21);
        recipe.setPrep_time_in_min(15);
        assertEquals((rec.get().getCuisine()),"indian");
        assertFalse("Not Italian",rec.get().getCuisine()=="Italian");
        assertFalse("only multiples of 5 allowed",rec.get().getTotal_time_in_min()==36);
    }
}
