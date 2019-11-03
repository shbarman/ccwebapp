package com.neu.ccwebapp.web;

import com.timgroup.statsd.NoOpStatsDClient;
import com.timgroup.statsd.NonBlockingStatsDClient;
import com.timgroup.statsd.StatsDClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.slf4j.LoggerFactory;
import org.slf4j.Logger;

@Configuration
public class MetricsClientConfig {

    @Value("${publish.metrics}")
    private boolean publishMetrics;

    @Value("${metrics.server.hostname}")
    private String metricsServerHost;

    @Value("${metrics.server.port}")
    private int metricsServerPort;


    private final static Logger logger = LoggerFactory.getLogger(MetricsClientConfig.class);


    @Bean
    public StatsDClient metricsClient(){

        logger.info("publish metrics "+ publishMetrics);
        if(publishMetrics){
            return new NonBlockingStatsDClient("csye6225", metricsServerHost, metricsServerPort);
        }
        return new NoOpStatsDClient();
    }

}