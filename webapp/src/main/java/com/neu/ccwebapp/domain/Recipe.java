package com.neu.ccwebapp.domain;



import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.neu.ccwebapp.validation.ValidPassword;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.validator.constraints.Range;

import javax.persistence.*;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.time.LocalDateTime;
import java.util.*;

@Entity

public class Recipe
{
    @Id
    @GeneratedValue
    @Column(name = "recipeId", columnDefinition = "BINARY(16)")
    private UUID recipeId;

    @CreationTimestamp
    @Column
    private Date created_ts;

    @UpdateTimestamp
    @Column
    private Date updated_ts;



    @Column(name = "authorid", columnDefinition = "BINARY(16)")
    private UUID authorid;

    @Column
    private Integer cook_time_in_min;

    @Column
    private String cuisine;

    @Column
    private Integer prep_time_in_min;

    @Column
    private Integer total_time_in_min;

    @Column
    private String title;



    @Column
    @Range(min=1, max=5)
    private Integer servings;

    @ElementCollection
    @Column
    private List<String> ingredients;



    @OneToMany(cascade = CascadeType.ALL,orphanRemoval = true)
    @JoinColumn(name="orderlist_recipeID")
    private Set<OrderedList> steps;


    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(unique = true)
    private NutritionInformation nutritionInformation;

//    public User getUser() {
//        return user;
//    }
//
//    public void setUser(User user) {
//        this.user = user;
//    }


    public UUID getAuthorid() {
        return authorid;
    }

    public void setAuthorid(UUID authorid) {
        this.authorid = authorid;
    }


    @ManyToOne(cascade = CascadeType.ALL, optional=true)
    @JoinColumn(name="userID",nullable=true)
    private User user;

    public UUID getRecipeId() {
        return recipeId;
    }

    public void setRecipeId(UUID recipeId) {
        this.recipeId = recipeId;
    }

    public Date getCreated_ts() {
        return created_ts;
    }

    public void setCreated_ts() {
        this.created_ts = new Date();
    }

    public Date getUpdated_ts() {
        return updated_ts;
    }

    public void setUpdated_ts() {
        this.updated_ts = new Date();
    }



    public Integer getCook_time_in_min() {
        return cook_time_in_min;
    }

    public Set<OrderedList> getSteps() {
        return steps;
    }

    public void setSteps(Set<OrderedList> steps) { this.steps = steps; }

    public void setCook_time_in_min(int cook_time_in_min) {

        this.cook_time_in_min = cook_time_in_min;


    }

    public Integer getPrep_time_in_min() {
        return prep_time_in_min;
    }

    public void setPrep_time_in_min(int prep_time_in_min) {

        this.prep_time_in_min = prep_time_in_min;
    }

    public Integer getTotal_time_in_min() {
        return total_time_in_min;
    }

    public void setTotal_time_in_min() {

        this.total_time_in_min = this.getCook_time_in_min() + this.getPrep_time_in_min();
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCuisine() {
        return cuisine;
    }

    public void setCuisine(String cuisine) {
        this.cuisine = cuisine;
    }

    public Integer getServings() {
        return servings;
    }

    public void setServings(int servings) {
        this.servings = servings;
    }

    public List<String> getIngredients() {
        return ingredients;
    }

    public void setIngredients(List<String> ingredients) {this.ingredients = ingredients; }



    public NutritionInformation getNutritionInformation() {
        return nutritionInformation;
    }

    public void setNutritionInformation(NutritionInformation nutritionInformation) {


        this.nutritionInformation = nutritionInformation;
    }


    public Recipe(){

    }




    public Recipe(Date created_ts, Date updated_ts, UUID authorid, Integer cook_time_in_min, Integer prep_time_in_min, Integer total_time_in_min, String title, String cuisine, @Range(min = 1, max = 5) Integer servings, List<String> ingredients, Set<OrderedList> steps, NutritionInformation nutritionInformation) {
        this.created_ts = created_ts;
        this.updated_ts = updated_ts;
        this.authorid = authorid;
        this.cook_time_in_min = cook_time_in_min;
        this.prep_time_in_min = prep_time_in_min;
        this.total_time_in_min = total_time_in_min;
        this.title = title;
        this.cuisine = cuisine;
        this.servings = servings;
        this.ingredients = ingredients;
        this.steps = steps;
        this.nutritionInformation = nutritionInformation;
    }
}
