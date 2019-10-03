package com.neu.ccwebapp.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.lang.Nullable;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import java.util.Date;
import java.util.UUID;

@Entity
public class NutritionInformation {

    @Id
    @GeneratedValue
    @Column(name = "id",columnDefinition = "BINARY(16)")
    private UUID id;

    @Column(nullable=false)
    private Integer calories;

    @Column(nullable=false)
    private Float cholesterol_in_mg;

    @Column(nullable=false)
    private Integer sodium_in_mg;

    @Column(nullable=false)
    private Float carbohydrates_in_grams;



    @Column(nullable=false)
    private Float protein_in_grams;


    public NutritionInformation(int calories, float cholesterol_in_mg, int sodium_in_mg, float carbohydrates_in_grams, float protein_in_grams) {
        this.calories = calories;
        this.cholesterol_in_mg = cholesterol_in_mg;
        this.sodium_in_mg = sodium_in_mg;
        this.carbohydrates_in_grams = carbohydrates_in_grams;
        this.protein_in_grams = protein_in_grams;
    }

    public NutritionInformation()
    {

    }
    @JsonIgnore
    public UUID getId() {
        return id;
    }

    @JsonProperty("id")
    public void setId(UUID id) {
        this.id = id;
    }

    public Integer getCalories() {
        return calories;
    }

    public void setCalories(int calories) {
        this.calories = calories;
    }

    public Float getCholesterol_in_mg() {
        return cholesterol_in_mg;
    }

    public void setCholesterol_in_mg(float cholesterol_in_mg) {
        this.cholesterol_in_mg = cholesterol_in_mg;
    }

    public Integer getSodium_in_mg() {
        return sodium_in_mg;
    }

    public void setSodium_in_mg(int sodium_in_mg) {
        this.sodium_in_mg = sodium_in_mg;
    }

    public Float getCarbohydrates_in_grams() {
        return carbohydrates_in_grams;
    }

    public void setCarbohydrates_in_grams(float carbohydrates_in_grams) {
        this.carbohydrates_in_grams = carbohydrates_in_grams;
    }

    public Float getProtein_in_grams() {
        return protein_in_grams;
    }

    public void setProtein_in_grams(float protein_in_grams) {
        this.protein_in_grams = protein_in_grams;
    }
}
