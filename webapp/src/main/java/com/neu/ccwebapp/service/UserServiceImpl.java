package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
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

    @Override
    public User registerUser(User user) throws UserExistsException {
        System.out.println("inside register");
        User existingUser = userRepository.findByUsername(user.getUsername());
        if(existingUser!=null) {
            throw new UserExistsException("A user with username "+user.getUsername() + " already exists");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));
        userRepository.save(user);
        return user;

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
            userRepository.save(userLoggedin);
        }
    }

    @Override
    public User loadUsername(String userName) {

        User u = userRepository.findByUsername(userName);

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
