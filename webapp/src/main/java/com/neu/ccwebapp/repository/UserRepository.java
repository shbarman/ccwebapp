package com.neu.ccwebapp.repository;

import com.neu.ccwebapp.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User,String> {
}
