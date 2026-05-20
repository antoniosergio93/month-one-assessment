variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "web_server_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for database"
  type        = string
  default     = "t3.small"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "AWS key pair name"
  type        = string
  default = "techcorp-key.pem"
}

variable "ip_address" {
  description = "Current public IP Address"
  type        = string
}


variable "ami" {
  description = "AMI ID for Host"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

