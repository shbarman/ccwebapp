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

import java.util.Optional;
import java.util.UUID;

import static org.junit.Assert.assertEquals;

@RunWith(SpringRunner.class)
@SpringBootTest
public class RecipeTests
{
	@Mock
 private UserRepository userRepository;
	@Mock
    private RecipeRepository recipeRepository;

    private User user;
    private Recipe recipe;
    private UUID recId;
    private UUID usrID;

    @Before
  public void setUp() {
        MockitoAnnotations.initMocks(this);
        this.user = new User();
         usrID = UUID.randomUUID();
        user.setUserID(usrID);
		user.setUsername("test@gmail.com");
		user.setPassword("PasswordPassword");
        Mockito.when(userRepository.findByUsername("test@gmail.com")).thenReturn(this.user);

        this.recipe = new Recipe();
         recId = UUID.randomUUID();
        recipe.setRecipeId(recId);
        recipe.setAuthorid(usrID);
        recipe.setTitle("Creamy Cajun Chicken Pasta");
        recipe.setCuisine("Italian");
        Mockito.when(recipeRepository.findById(recId)).thenReturn(java.util.Optional.ofNullable(this.recipe));


    }

    @Test
    public void TestSave() {
    Optional<Recipe> rec = recipeRepository.findById(recId);
    assertEquals(rec.get().getAuthorid(),usrID);
    assertEquals(rec.get().getCuisine(),"Italian");
    }


}
