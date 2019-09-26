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
    public void registerUser(User user) throws UserExistsException {
        System.out.println("inside register");
        Optional<User> existingUser = userRepository.findById(user.getUsername());
        if(existingUser.isPresent()) {
            throw new UserExistsException("A user with username "+user.getUsername() + " already exists");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));
        userRepository.save(user);

    }
    public void updateUser(String name, User user) throws UserExistsException {

        String id = user.getUsername();



        User userLoggedin = userRepository.findById(name).get();

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

        Optional<User> u = userRepository.findById(userName);
        User filteredUser = u.get();

        return filteredUser;
    }

    @Override
    public UserDetails loadUserByUsername(String userName) throws UsernameNotFoundException
    {
        Optional<User> user = userRepository.findById(userName);
        if(user.isPresent())
        {
            throw new UsernameNotFoundException("No user found with the username : "+userName);
        }
        List<GrantedAuthority> authorities = new ArrayList<GrantedAuthority>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
        return new org.springframework.security.core.userdetails.User(user.get().getUsername(), user.get().getPassword(), authorities);
    }
}
