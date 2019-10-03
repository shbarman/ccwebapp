
package com.neu.ccwebapp.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import javax.persistence.*;
import java.util.UUID;

@Entity
public class OrderedList {



    @Id
    @GeneratedValue
    @Column(name = "orderID", columnDefinition = "BINARY(16)")
    private UUID  orderID;

    @Column
    private Integer position;

    @Column
    private String items;

    @JsonIgnore
    public UUID getOrderID() {
        return orderID;
    }

    @JsonProperty("orderID")
    public void setOrderID(UUID orderID) {
        this.orderID = orderID;
    }



    public Integer getPosition() {
        return position;
    }

    public void setPosition(int position) {
        this.position = position;
    }

    public String getItems() {
        return items;
    }

    public void setItems(String items) {
        this.items = items;
    }


}



