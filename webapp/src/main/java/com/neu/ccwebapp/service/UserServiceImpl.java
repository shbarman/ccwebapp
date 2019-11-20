package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.repository.UserRepository;
import com.neu.ccwebapp.web.AppController;
import com.timgroup.statsd.StatsDClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class UserServiceImpl implements UserService, UserDetailsService
{
    @Autowired
    UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private StatsDClient statsDClient;

    private final static Logger logger = LoggerFactory.getLogger(UserServiceImpl.class);

    @Override
    public User registerUser(User user) throws UserExistsException {

        User existingUser = userRepository.findByUsername(user.getUsername());
        if(existingUser!=null) {
            throw new UserExistsException("A user with username "+user.getUsername() + " already exists");
        }

        try {
            passwordEncoder= new BCryptPasswordEncoder();
            user.setPassword(passwordEncoder.encode(user.getPassword()));
            long startTime = System.currentTimeMillis();

            userRepository.save(user);
            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("dbQueryTimeUpdateUser", duration);

            logger.info("New User has been added to the DB");
        } catch (Exception e){
            return null;
        }
        return  user;

    }




    public void updateUser(String name, User user) throws UserExistsException {

        String id = user.getUsername();



        User userLoggedin = userRepository.findByUsername(name);

        if (userLoggedin.getUsername() == null) {

            throw new UsernameNotFoundException("No user found with the username : " + name
            );
        } else {

            userLoggedin.setUsername(user.getUsername());
            userLoggedin.setFirst_name(user.getFirst_name());
            userLoggedin.setLast_name(user.getLast_name());
            userLoggedin.setPassword(passwordEncoder.encode(user.getPassword()));
            long startTime =  System.currentTimeMillis();

            userRepository.save(userLoggedin);
            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("dbQueryTimeUpdateUser",duration);

            logger.info("User details are updated in the DB");

        }
    }

    @Override
    public User loadUsername(String userName) {

        long startTime =  System.currentTimeMillis();

        User u = userRepository.findByUsername(userName);

        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);

        statsDClient.recordExecutionTime("dbQueryTimeGetUser",duration);

      logger.info("Getting user from the DB ");

        return u;
    }

    @Override
    public UserDetails loadUserByUsername(String userName) throws UsernameNotFoundException
    {
        User user = userRepository.findByUsername(userName);
        if(user==null)
        {
            throw new UsernameNotFoundException("No user found with the username : "+userName);
        }
        List<GrantedAuthority> authorities = new ArrayList<GrantedAuthority>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
        return new org.springframework.security.core.userdetails.User(user.getUsername(), user.getPassword(), authorities);
    }
}
