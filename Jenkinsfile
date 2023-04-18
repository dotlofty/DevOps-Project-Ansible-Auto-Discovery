pipeline{
    agent any
    tools{
        maven 'maven'
    }
    environment{
        dockerusername = credentials('dockerhub-username')
        dockerpassword = credentials('dockerhub-password')
    }
    stages{
       stage('Git pull'){
          steps{
             git branch: 'main', credentialsId: 'git', url: 'https://github.com/CloudHight/Pet-Adoption-Containerisation-Project-Application-Day-Team--06-Feb.git' 
          } 
       }
       stage('Build Code'){
           steps{
               sh 'mvn clean install'
           }
       }
       stage('Build Image'){
           steps{
               sh 'docker build -t $dockerusername/pipeline:1.0.11 .'
           }
       }
       stage('Log into Dockerhub'){
           steps{
               sh 'docker login -u $dockerusername -p $dockerpassword'
           }
       }
       stage('Push Image'){
           steps{
               sh 'docker push $dockerusername/pipeline:1.0.11'
           }
       }
       stage('Deploy to Stage'){
           steps{
               sshagent(['jenkins-key']){
                   sh 'ssh -t -t ec2-user@10.0.1.168 -o StrictHostKeyChecking=no "ansible-playbook -i /etc/ansible/stage_hosts /home/ec2-user/playbooks/stage_auto_discovery.yml"'
               }
           }
       }
       stage('Slack Notifications'){
           steps{
               slackSend channel: 'jenkins-alert', message: 'successfully deployed to Stage Env need approval to deploy to PROD Env', teamDomain: 'dothrakiinter-evh4406', tokenCredentialId: 'slack'
           }
       }
       stage('Approval'){
           steps{
               timeout(activity: true, time: 5){
                   input message: 'need approval to deploy to production ', submitter: 'admin'
               }
           }
       }
       stage('Deploy to Prod'){
           steps{
               sshagent(['jenkins-key']){
                   sh 'ssh -t -t ec2-user@10.0.1.168 -o StrictHostKeyChecking=no "ansible-playbook /home/ec2-user/playbooks/PROD_Auto_Discovery.yml"'
               }
           }
       }
       
    }
    post{
       success{
          slackSend channel: 'jenkins-alert', message: 'successfully deployed to PROD Env ', teamDomain: 'dothrakiinter-evh4406', tokenCredentialId: 'slack' 
       }
       falure{
           slackSend channel: 'jenkins-alert', message: 'failed to deploy to PROD Env', teamDomain: 'dothrakiinter-evh4406', tokenCredentialId: 'slack'
       }
    }
}