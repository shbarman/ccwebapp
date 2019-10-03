package com.neu.ccwebapp.repository;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.UUID;


public interface RecipeRepository extends JpaRepository<Recipe, UUID> {


}
