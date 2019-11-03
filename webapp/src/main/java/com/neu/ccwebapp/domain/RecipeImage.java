package com.neu.ccwebapp.domain;

//        import lombok.Getter;
//        import lombok.Setter;
//        import lombok.ToString;

        import com.fasterxml.jackson.annotation.JsonIgnore;
        import com.fasterxml.jackson.annotation.JsonProperty;

        import javax.persistence.Column;
        import javax.persistence.Entity;
        import javax.persistence.GeneratedValue;
        import javax.persistence.Id;
        import java.util.UUID;

@Entity
//@Getter
//@Setter
//@ToString
public class RecipeImage {



    @Id
    @GeneratedValue
    @Column(name = "image_id", columnDefinition = "BINARY(16)")
    private UUID id;

    private String url;



    private String md5;



    public RecipeImage() {
    }

    public RecipeImage(String url) {
        this.url = url;
    }

    public RecipeImage(UUID id, String url) {
        this.id = id;
        this.url = url;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    @JsonIgnore
    public String getMd5() {
        return md5;
    }

    @JsonProperty("md5")
    public void setMd5(String md5) {
        this.md5 = md5;
    }
}
