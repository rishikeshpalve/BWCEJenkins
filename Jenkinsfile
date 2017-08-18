pipeline {
  agent any
  stages {
    stage('Checkout Code') {
      steps {
        git(url: 'https://github.com/rishikeshpalve/BWCEJenkins.git', branch: 'master')
      }
    }
    stage('Build EAR & Docker Image') {
      steps {
        sh '/usr/local/maven/apache-maven-3.3.9/bin/mvn -f ./*.parent/pom.xml clean package docker:build'
      }
    }
    stage('Publish to ECR') {
      steps {
        sh '''sudo su
        DOCKER_LOGIN='aws ecr get-login --region us-east-1'
        ${DOCKER_LOGIN}
        /usr/local/maven/apache-maven-3.3.9/bin/mvn -f ./*.parent/pom.xml initialize docker:push'''
      }
    }
    stage('Deploy on ECS') {
      steps {
        sh '''        #!/bin/bash
        #Constants
        
        REGION=us-east-1
        REPOSITORY_NAME=bwce-app
        CLUSTER=bw-test
        SERVICE_NAME=bwce-app-svc-10
        TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:us-east-1:928133119666:targetgroup/default/4204ca217de9c8cb
        IAM_ROLE=arn:aws:iam::928133119666:role/BWCEonAWS
        
        #Store the repositoryUri as a variable
        REPOSITORY_URI=`aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${REGION} | jq .repositories[].repositoryUri | tr -d '"'`
        
        aws logs create-log-group --log-group-name bwce-app-log --region us-east-1 || true
        
        #Register the task definition in the repository
        aws ecs register-task-definition --family launch-test-app --cli-input-json file://${WORKSPACE}/taskdef.json --region ${REGION}
        SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .failures[]`
        #Get latest revision
        REVISION=`aws ecs describe-task-definition --task-definition launch-test-app --region ${REGION} | jq .taskDefinition.revision`
        
        #Create or update service
        if [ "$SERVICES" == "" ]; then
          echo "entered existing service"
          DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .services[].desiredCount`
          if [ ${DESIRED_COUNT} = "0" ]; then
            DESIRED_COUNT="1"
          fi
          aws ecs update-service --cluster ${CLUSTER} --region ${REGION} --service ${SERVICE_NAME} --task-definition launch-test-app:${REVISION} --desired-count ${DESIRED_COUNT} --load-balancers targetGroupArn=${TARGET_GROUP_ARN},containerName=bwce-test-app,containerPort=8080
        else
          echo "entered new service"
          aws ecs create-service --service-name ${SERVICE_NAME} --desired-count 1 --task-definition launch-test-app --load-balancers targetGroupArn=${TARGET_GROUP_ARN},containerName=bwce-test-app,containerPort=8080 --role ${IAM_ROLE} --cluster ${CLUSTER} --region ${REGION}
        fi'''
      }
    }
  }
}