module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  name                  = var.vpc_name
  cidr                  = var.vpc_cidr
  azs                   = [var.az1, var.az2]
  private_subnets       = [var.priv_subnet1, var.priv_subnet2]
  public_subnets        = [var.pub_subnet1, var.pub_subnet2]
  enable_nat_gateway    = true
  single_nat_gateway    = false
  one_nat_gateway_per_az = true

  tags = {
    Terraform = "true"
    Environment = "dev"
    Name = "${var.name}-vpc"
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name   = var.key
  public_key = file("~/keypairs/lofty.pub")
}

module "sg" {
  source = "./local-module/sg"
  dotunvpc_id = module.vpc.vpc_id
}

module "Bastion" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-Bastion"
  ami                    = var.ec2-ami
  instance_type          = var.instancetype
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.bastion-sg-id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data              = templatefile("./User_data/bastion.sh",
    {
      keypair = "~/keypairs/lofty"
    }
  )

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.name}-Bastion"
  }
}

# ec2_iam
module "ec2_iam" {
  source                  = "./local-module/ec2_iam"
}

module "Ansible" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-Ansible"
  ami                    = var.ec2-ami
  instance_type          = var.instancetype
  iam_instance_profile   = module.ec2_iam.iam-profile-name
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.ansible-sg-id]
  subnet_id              = module.vpc.private_subnets[0]
    user_data = templatefile("./User_data/ansible.sh",
    {
      keypair               = "~/keypairs/lofty",
      STAGEcontainer        = "./playbooks/STAGEcontainer.yml",
      stage_auto_discovery  = "./playbooks/stage_auto_discovery.yml",
      stage_runner          = "./playbooks/stage_runner.yml",
      PRODcontainer         = "./playbooks/PRODcontainer.yml",
      PROD_Auto_Discovery   = "./playbooks/PROD_Auto_Discovery.yml",
      PROD_runner           = "./playbooks/PROD_runner.yml",
      vault_password        = "./playbooks/Vault_pass.yml",
      new_relic_key         = var.new_relic_key,
      doc_pass              = var.doc_pass,
      doc_user              = var.doc_user
    }
  )

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.name}-Ansible"
  }
}

module "Docker" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-Docker"
  ami                    = var.ec2-ami
  instance_type          = var.instancetype
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.docker-sg-id]
  subnet_id              = module.vpc.private_subnets[0]
  count                  = 3
  user_data              = file("./User_data/docker.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.docker_name}${count.index}"
  }
}

#Create Continuous Testing Instance
module "testingEC2" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-testingEC2"
  ami                    = var.ec2-ami
  instance_type          = var.instancetype
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.docker-sg-id]
  subnet_id              = module.vpc.private_subnets[0]
  user_data              = file("./User_data/testingEC2.sh")

  tags = {
    Terraform   = "true"
    Environment = "Staging"
    Name        = "${var.name}-testingEC2"
  }
}

module "Jenkins" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-Jenkins"
  ami                    = var.ec2-ami
  instance_type          = var.instancetypeJ
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.jenkins-sg-id]
  subnet_id              = module.vpc.private_subnets[0]
  user_data = templatefile("./User_data/jenkins.sh", {
  new_relic_key = var.new_relic_key
  }) 
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.name}-Jenkins"
  }
}

module "jenkins_elb" {
  source = "./local-module/jenkins_elb"
  subnet_id1 = module.vpc.public_subnets[0]
  subnet_id2 = module.vpc.public_subnets[1]
  security_id = module.sg.alb-sg-id
  jenkins_id = module.Jenkins.id
}

module "sonarqube" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "${var.name}-sonar"
  ami                    = var.ec2-ami
  instance_type          = var.instancetype
  key_name               = module.key_pair.key_pair_name
  vpc_security_group_ids = [module.sg.sonarQube-sg-id]
  subnet_id              = module.vpc.public_subnets[0]
  user_data = file("./User_data/sonar.sh")
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.name}-sonar"
  }
}

module "ALB" {
  source = "./local-module/ALB"
  ALB_security = module.sg.alb-sg-id
  ALB-subnet1 = module.vpc.public_subnets[0]
  ALB-subnet2 = module.vpc.public_subnets[1]
  vpc_name = module.vpc.vpc_id
  Target_EC2 = module.Docker[1].id
}

module "Stage_ALB" {
  source = "./local-module/Stage_ALB"
  ALB_security = module.sg.alb-sg-id
  ALB-subnet1 = module.vpc.public_subnets[0]
  ALB-subnet2 = module.vpc.public_subnets[1]
  vpc_name = module.vpc.vpc_id
  Target_EC2 = module.Docker[1].id
}

module "ASG" {
  source = "./local-module/ASG"
  vpc-subnet1 = module.vpc.public_subnets[0]
  vpc-subnet2 = module.vpc.public_subnets[1]
  albtg-arn = module.ALB.alb-TG
  ASG-sg = module.sg.docker-sg-id
  key_pair = module.key_pair.key_pair_name
  asg_EC2 = module.Docker[2].id
}

module "Stage_ASG" {
  source = "./local-module/Stage_ASG"
  vpc-subnet1 = module.vpc.public_subnets[0]
  vpc-subnet2 = module.vpc.public_subnets[1]
  albtg-arn = module.ALB.alb-TG
  ASG-sg = module.sg.docker-sg-id
  key_pair = module.key_pair.key_pair_name
  Stage_asg_EC2 = module.Docker[1].id
}

module "AWS_ACM" {
  source = "./local-module/AWS_ACM"
  alb-arn = module.ALB.alb-arn
  albtg-arn = module.ALB.alb-TG
  prod-lb_dns = module.ALB.alb-DNS
  prod-lb_zoneid = module.ALB.alb-zone-id
  alb-arn2 = module.Stage_ALB.alb-arn
  albtg-arn2 = module.Stage_ALB.alb-TG
  stage-lb_dns = module.Stage_ALB.alb-DNS
  stage-lb_zoneid = module.Stage_ALB.alb-zone-id
}

module "Route53" {
  source = "./local-module/Route53"
  lb_dns = module.ALB.alb-DNS
  lb_zoneid = module.ALB.alb-zone-id
}