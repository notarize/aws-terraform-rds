terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.2"
  region  = "us-east-1"
}

provider "aws" {
  region = "us-west-2"
  alias  = "oregon"
}

data "aws_kms_secrets" "rds_credentials" {
  secret {
    name    = "password"
    payload = "AQICAHj9P8B8y7UnmuH+/93CxzvYyt+la85NUwzunlBhHYQwSAG+eG8tr978ncilIYv5lj1OAAAAaDBmBgkqhkiG9w0BBwagWTBXAgEAMFIGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMoasNhkaRwpAX9sglAgEQgCVOmIaSSj/tJgEE5BLBBkq6FYjYcUm6Dd09rGPFdLBihGLCrx5H"
  }
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.0"

  name = "Test1VPC"
}

module "vpc_dr" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.0"

  name = "Test2VPC"

  providers = {
    aws = aws.oregon
  }
}

####################################################################################################
# Mariadb Master                                                                                   #
####################################################################################################

module "rds_master" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.0"

  ##################
  # Required Configuration
  ##################

  engine            = "mariadb"                                                  #  Required
  instance_class    = "db.t2.large"                                              #  Required
  name              = "sample-mariadb-rds"                                       #  Required
  password          = data.aws_kms_secrets.rds_credentials.plaintext["password"] #  Required
  security_groups   = [module.vpc.default_sg]                                    #  Required
  storage_encrypted = true                                                       #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets           = module.vpc.private_subnets                                 #  Required
  # username        = "dbadmin"

  ##################
  # VPC Configuration
  ##################

  # create_subnet_group   = true
  # existing_subnet_group = "some-subnet-group-name"

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "10.2.12"
  # port                  = "3306"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"
  # timezone              = "US/Central"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade    = true
  # create_option_group           = true
  # create_parameter_group        = true
  # existing_option_group_name    = "some-option-group-name"
  # existing_parameter_group_name = "some-parameter-group-name"
  # family                        = "mariadb10.2"
  # kms_key_id                    = "some-kms-key-id"
  # multi_az                      = false
  # options                       = []
  # parameters                    = []
  # publicly_accessible           = false
  # storage_encrypted             = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_cpu_limit          = 60
  # alarm_free_space_limit   = 1024000000
  # alarm_read_iops_limit    = 100
  # alarm_write_iops_limit   = 100
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }
}

####################################################################################################
# Mariadb Same Region Replica                                                                     #
####################################################################################################

module "rds_replica" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.0"

  ##################
  # Required Configuration
  ##################

  create_parameter_group        = false
  create_option_group           = false
  create_subnet_group           = false
  existing_option_group_name    = module.rds_master.option_group
  existing_parameter_group_name = module.rds_master.parameter_group
  existing_subnet_group         = module.rds_master.subnet_group
  engine                        = "mariadb"               #  Required
  instance_class                = "db.t2.large"           #  Required
  name                          = "sample-mariadb-rds-rr" #  Required
  password                      = ""                      #  Retrieved from source DB
  read_replica                  = true
  security_groups               = [module.vpc.default_sg] #  Required
  source_db                     = module.rds_master.db_instance
  storage_encrypted             = true                       #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets                       = module.vpc.private_subnets #  Required

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "10.2.12"
  # port                  = "3306"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"
  # timezone              = "US/Central"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade    = true
  # family                        = "mariadb10.2"
  # kms_key_id                    = "some-kms-key-id"
  # multi_az                      = false
  # options                       = []
  # parameters                    = []
  # publicly_accessible           = false
  # storage_encrypted             = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_cpu_limit          = 60
  # alarm_free_space_limit   = 1024000000
  # alarm_read_iops_limit    = 100
  # alarm_write_iops_limit   = 100
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"
  # rackspace_alarms_enabled = true

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }
}

####################################################################################################
# Mariadb Cross Region Replica                                                                     #
####################################################################################################

data "aws_kms_alias" "rds_crr" {
  provider = aws.oregon
  name     = "alias/aws/rds"
}

module "rds_cross_region_replica" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-rds?ref=v0.12.0"

  #######################
  # Required parameters #
  #######################

  engine            = "mariadb"                                 #  Required
  instance_class    = "db.t2.large"                             #  Required
  kms_key_id        = data.aws_kms_alias.rds_crr.target_key_arn # Parameter needed since we are replicating an db instance with encrypted storage.
  name              = "sample-mariadb-rds-crr"                  #  Required
  password          = ""                                        #  Retrieved from source DB
  read_replica      = true
  security_groups   = [module.vpc_dr.default_sg] #  Required
  source_db         = module.rds_master.db_instance_arn
  storage_encrypted = true                          #  Parameter defaults to false, but enabled for Cross Region Replication example
  subnets           = module.vpc_dr.private_subnets #  Required

  ##################
  # VPC Configuration
  ##################

  # create_subnet_group   = true
  # existing_subnet_group = "some-subnet-group-name"

  ##################
  # Backups and Maintenance
  ##################

  # backup_retention_period = 35
  # backup_window           = "05:00-06:00"
  # db_snapshot_id          = "some-snapshot-id"
  # maintenance_window      = "Sun:07:00-Sun:08:00"

  ##################
  # Basic RDS
  ##################

  # copy_tags_to_snapshot = true
  # dbname                = "mydb"
  # engine_version        = "10.2.12"
  # port                  = "3306"
  # storage_iops          = 0
  # storage_size          = 10
  # storage_type          = "gp2"
  # timezone              = "US/Central"

  ##################
  # RDS Advanced
  ##################

  # auto_minor_version_upgrade    = true
  # create_option_group           = true
  # create_parameter_group        = true
  # existing_option_group_name    = "some-option-group-name"
  # existing_parameter_group_name = "some-parameter-group-name"
  # family                        = "mariadb10.2"
  # kms_key_id                    = "some-kms-key-id"
  # multi_az                      = false
  # options                       = []
  # parameters                    = []
  # publicly_accessible           = false
  # storage_encrypted             = false

  ##################
  # RDS Monitoring
  ##################

  # alarm_cpu_limit          = 60
  # alarm_free_space_limit   = 1024000000
  # alarm_read_iops_limit    = 100
  # alarm_write_iops_limit   = 100
  # existing_monitoring_role = ""
  # monitoring_interval      = 0
  # notification_topic       = "arn:aws:sns:<region>:<account>:some-topic"
  # rackspace_alarms_enabled = true

  ##################
  # Other parameters
  ##################

  # environment = "Production"

  # tags = {
  #   SomeTag = "SomeValue"
  # }

  providers = {
    aws = aws.oregon
  }
}
