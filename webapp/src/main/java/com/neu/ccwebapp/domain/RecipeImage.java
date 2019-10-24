package com.neu.ccwebapp.domain;

//        import lombok.Getter;
//        import lombok.Setter;
//        import lombok.ToString;

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
}
