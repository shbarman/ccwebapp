package com.neu.ccwebapp.service;

import com.neu.ccwebapp.domain.User;
import com.neu.ccwebapp.exceptions.UserExistsException;
import com.neu.ccwebapp.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Override
    public void registerUser(User user) throws UserExistsException {
        userRepository.save(user);
    }

    @Override
    public UserDetails loadUserByUsername(String userName) throws UsernameNotFoundException
    {
        Optional<User> user = userRepository.findById(userName);
        List<GrantedAuthority> authorities = new ArrayList<GrantedAuthority>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
        return new org.springframework.security.core.userdetails.User(user.get().getUsername(), user.get().getPassword(), authorities);
    }
}
