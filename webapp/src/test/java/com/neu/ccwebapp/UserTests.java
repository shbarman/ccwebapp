package com.neu.ccwebapp;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.repository.UserRepository;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;
import java.util.Set;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

@RunWith(SpringRunner.class)
@SpringBootTest
public class UserTests
{
	@Mock
 private UserRepository userRepository;

    private User user;

    @Before
  public void setUp() {
        MockitoAnnotations.initMocks(this);
        this.user = new User();
		user.setUsername("test@gmail.com");
		user.setPassword("PasswordPassword");
        Mockito.when(userRepository.findByUsername("test@gmail.com")).thenReturn(this.user);
    }

    @Test
    public void TestfindByEmailAddressPositive() {
        User u = userRepository.findByUsername("test@gmail.com");
        assertEquals(u.getUsername(), "test@gmail.com");
    }
}
