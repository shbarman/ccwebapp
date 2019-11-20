package com.neu.ccwebapp;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.repository.UserRepository;
import com.neu.ccwebapp.service.UserServiceImpl;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.springframework.test.context.junit4.SpringRunner;

import java.time.LocalDateTime;
import java.util.UUID;




@RunWith(SpringRunner.class)
public class UserServiceTest {


    @InjectMocks
    private UserServiceImpl userService;

    @Mock
    private UserRepository userRepo;

    private static User user;

    @Before
    public void setUp() {

        this.user = new User(UUID.randomUUID(), "Harshitha", "Somasundar", "harshuss94@gmail.com", "WonderFul@28",  LocalDateTime.now(), LocalDateTime.now());
    }

    @Test
    public void userRegisterTest() throws Exception {
        System.out.println("user is "+ user.getUsername());
        userService.registerUser(user);
        Mockito.verify(userRepo).save(user);
    }
}

