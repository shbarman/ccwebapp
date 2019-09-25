package com.neu.ccwebapp;

import com.neu.ccwebapp.domain.User;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import javax.validation.ConstraintViolation;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorFactory;
import java.util.Set;

import static org.junit.Assert.assertFalse;

@RunWith(SpringRunner.class)
@SpringBootTest
public class CcwebappApplicationTests
{
	private Validator validator;

	@Before
	public void setUp() {
		ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
		validator = factory.getValidator();
	}

	@Test
	public void testPasswordValidation()
	{
		User user = new User();
		user.setUsername("karun@gmail.com");
		user.setPassword("PasswordPassword");
		Set<ConstraintViolation<User>> violations = validator.validate(user);
		assertFalse(violations.isEmpty());
	}

}
