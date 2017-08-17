FROM 928133119666.dkr.ecr.us-east-1.amazonaws.com/tibco-bwce:latest
MAINTAINER Tibco
ADD bwce-test-app.application_1.0.0.ear /
EXPOSE 8080


