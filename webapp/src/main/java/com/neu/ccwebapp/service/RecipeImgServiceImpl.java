package com.neu.ccwebapp.service;



import com.amazonaws.auth.*;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.*;

import com.neu.ccwebapp.web.AppController;
import com.timgroup.statsd.StatsDClient;
import org.springframework.beans.factory.annotation.Autowired;
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

    @Autowired
    private StatsDClient statsDClient;


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
    public RecipeImage uploadImage(MultipartFile multipartFile, String fileName,RecipeImage recipeImage) throws Exception {
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

        long startTime =  System.currentTimeMillis();
        PutObjectResult data= s3client.putObject(bucketName, name, multipartFile.getInputStream(), new ObjectMetadata());

        long endTime = System.currentTimeMillis();

        long duration = (endTime - startTime);

        statsDClient.recordExecutionTime("S3PutImageRecipe",duration);

        logger.info("Image is successfully pushed to S3 bucket");

        String fileUrl = endpointUrl + "/" + bucketName + "/" + name;
        recipeImage.setUrl(fileUrl);
        recipeImage.setMd5(data.getContentMd5());


        UUID Id = UUID.randomUUID(); // Generating UUID for Bookimage Id

        recipeImage.setId(Id);

        return recipeImage;

    }






    @Override
    public String deleteImage(Optional<RecipeImage> recipeImage, UUID recipeID) throws Exception {
        String fileUrl= recipeImage.get().getUrl();



        String fileName = "Images/"+recipeID+"/"+fileUrl.substring(fileUrl.lastIndexOf("/") + 1);


        for (S3ObjectSummary file : s3client.listObjects(bucketName, fileName).getObjectSummaries()){

            long startTime =  System.currentTimeMillis();

            s3client.deleteObject(bucketName, file.getKey());

            long endTime = System.currentTimeMillis();

            long duration = (endTime - startTime);

            statsDClient.recordExecutionTime("S3DeleteImageRecipe",duration);

            logger.info("Successfully deleted  Image from S3 bucket ");


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