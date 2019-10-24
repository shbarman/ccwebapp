package com.neu.ccwebapp.service;



import com.amazonaws.auth.*;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.annotation.PostConstruct;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.neu.ccwebapp.domain.Recipe;
import com.neu.ccwebapp.domain.RecipeImage;

@Service
public class RecipeImgServiceImpl implements RecipeImgService {

    private final static Logger logger = LoggerFactory.getLogger(RecipeImgService.class);

    private AmazonS3 s3client;

    private String dir = "Images";



    @Value("${amazonProperties.endpointUrl}")
    private String endpointUrl;
    @Value("${amazonProperties.bucketName}")
    private String bucketName;
    @Value("${amazonProperties.accessKey}")
    private String accessKey;
    @Value("${amazonProperties.secretKey}")
    private String secretKey;




    @PostConstruct
    private void initializeAmazon() {
        AWSCredentials credentials = new BasicAWSCredentials(this.accessKey, this.secretKey);
        this.s3client = AmazonS3ClientBuilder.standard().withCredentials(new AWSStaticCredentialsProvider(credentials)).build();

    }

    @Override
    public String uploadImage(MultipartFile multipartFile, String fileName) throws Exception {
        //  String fileName = (new Date().toString() + "-" + multipartFile.getOriginalFilename()).replace(" ", "_");

        logger.info(multipartFile.getName());

        String name = this.dir + "/" + fileName;

        logger.info(name);

        InputStream inputStream = null;
        try {
            inputStream = multipartFile.getInputStream();

        } catch (IOException e) {
            e.printStackTrace();
        }

        s3client.putObject(bucketName, name, multipartFile.getInputStream(), new ObjectMetadata());

        String fileUrl = endpointUrl + "/" + bucketName + "/" + name;

        return fileUrl;

    }






    @Override
    public String deleteImage(Optional<RecipeImage> recipeImage, UUID recipeID) throws Exception {
        String fileUrl= recipeImage.get().getUrl();

       System.out.println("filename is "+ fileUrl);

        String fileName = "Images/"+recipeID+"/"+fileUrl.substring(fileUrl.lastIndexOf("/") + 1);
        System.out.println("filename is "+ fileName);

        for (S3ObjectSummary file : s3client.listObjects(bucketName, fileName).getObjectSummaries()){
            s3client.deleteObject(bucketName, file.getKey());
        }
        return "Successfully deleted";


    }

    @Override
    public String getFile(Optional<RecipeImage> recipeImage) throws Exception {
        String name= recipeImage.get().getUrl();
        java.util.Date expiration = new java.util.Date();
        long expTimeMillis = expiration.getTime();
        expTimeMillis += 1000 * 120;
        expiration.setTime(expTimeMillis);

        s3client.generatePresignedUrl(bucketName,name,expiration);
        logger.info(String.valueOf(s3client.generatePresignedUrl(bucketName,name,expiration)));


        return String.valueOf(s3client.generatePresignedUrl(bucketName,name,expiration));
    }
}