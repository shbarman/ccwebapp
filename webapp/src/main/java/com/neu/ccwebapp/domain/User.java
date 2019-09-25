package com.neu.ccwebapp.domain;



import javax.persistence.Entity;
import javax.persistence.Id;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;

@Entity
public class User
{
    @Id
    @NotNull(message = "Username not provided")
    @Pattern(regexp = "^[_A-Za-z0-9-+]+(\\.[_A-Za-z0-9-]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})$",message="Please provide a valid email address")
    private String username;

    @NotNull(message = "Password not provided")
  /*  @ValidPassword*/
    private String password;

    @NotNull(message = "Password not provided")
    private String first_name;

    @NotNull(message = "Password not provided")
    private String last_name;

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

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
