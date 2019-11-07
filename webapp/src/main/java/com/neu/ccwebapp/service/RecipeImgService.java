package com.neu.ccwebapp.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.RecipeImage;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;
import java.util.UUID;



public interface RecipeImgService {

    String JPEG = "image/jpeg";
    String JPG = "image/jpg";
    String PNG = "image/png";

    AmazonS3 s3 = AmazonS3ClientBuilder.standard()
            .build();

    default boolean isImagePresent(MultipartFile imageFile) {
        if(imageFile == null) return false;
        return true;
    }

    default boolean isFileFormatRight(String fileMimeType) {
        if(fileMimeType.equals(JPEG) || fileMimeType.equals(JPG) || fileMimeType.equals(PNG)) return true;
        return false;
    }

//    RecipeImage getPresignedUrl(UUID id);
//
//    RecipeImage getRecipeImageById(UUID id);
//
//    String writeFile(MultipartFile imageFile, UUID id, String localPath) throws Exception;
//
//    RecipeImage addRecipeImage(Optional<Recipe> recipe, MultipartFile imageFile, String localPath) throws Exception;
//
//    void deleteFile(String fileName) throws Exception;
//
//    //   void updateCover(Book book, Cover cover, MultipartFile imageFile, String localPath) throws Exception;
//
//    void deleteRecipeImg(Optional<Recipe> recipe, RecipeImage recipeImg) throws Exception;

    public RecipeImage uploadImage(MultipartFile multipartFile, String emailAddress,RecipeImage recipeImage) throws Exception;



    public String deleteImage(Optional<RecipeImage> recipeImage,UUID recipeID) throws Exception;
    public String getFile(Optional<RecipeImage> recipeImage) throws Exception;
}



