package com.neu.ccwebapp.domain;



import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.neu.ccwebapp.validation.ValidPassword;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.GenericGenerator;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity

public class User
{
    @Id
    @NotNull(message = "Username not provided")
    @Pattern(regexp = "^[_A-Za-z0-9-+]+(\\.[_A-Za-z0-9-]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$",message="Please provide a valid email address")
    private String username;


    /*@JsonIgnore*/
    @NotNull(message = "Password not provided")
    @ValidPassword

    private String password;

    @NotNull(message = "firstname not provided")
    private String first_name;

    @NotNull(message = "lastname not provided")
    private String last_name;

    @UpdateTimestamp
    @Column
    private LocalDateTime account_updated;

    @CreationTimestamp
    private LocalDateTime account_created;

    public String getUsername() {
        System.out.println(username);
        return username;
    }

    public void setUsername(String username) {

        System.out.println(username);
        this.username = username;
    }

    @JsonIgnore
    public String getPassword() {
        return password;
    }

    @JsonProperty("password")
    public void setPassword(String password) {
        this.password = password;
    }

    public String getFirst_name() {
        return first_name;
    }

    public void setFirst_name(String first_name) {
        this.first_name = first_name;
    }

    public String getLast_name() {
        return last_name;
    }

    public void setLast_name(String last_name) {
        this.last_name = last_name;
    }
}
