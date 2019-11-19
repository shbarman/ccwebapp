package com.neu.ccwebapp.repository;

import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.User;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;


public interface RecipeRepository extends JpaRepository<Recipe, UUID> {

  //  @Query(value = "SELECT * FROM RECIPE WHERE  authorid= ?1", nativeQuery = true)
    List<Recipe> findByAuthorid(UUID authorid);
  List<Recipe> findFirstByCreated_ts();
}
