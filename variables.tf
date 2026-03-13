variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID used to build the assumed role ARN."
  type        = string
  default     = "969578072702"
}

variable "project_name" {
  description = "Used in resource names and tags."
  type        = string
  default     = "terraform-zadaci"
}

variable "environment" {
  description = "e.g. dev, staging, prod — used in names and tags."
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "S3 bucket that stores Terraform state (created outside this config)."
  type        = string
  default     = "terraform-state-bucket-uddspring"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "ingress_ports" {
  description = "Ingress ports allowed to reach the web security group."
  type        = list(number)
  default     = [80, 22]
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for the EC2 key pair."
  type        = string
  default     = "~/.ssh/terraform-zadaci.pub"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach the web security group."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_egress_cidr_blocks" {
  description = "CIDR blocks the web security group can reach outbound."
  type        = list(string)
  default     = ["0.0.0.0/0"]

}

# static AMI ID with a us-east-1-specific note, can be issue, if it drifts
# that way it suggest lookup
variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023 in us-east-1 by default)."
  type        = string
  default     = "ami-02dfbd4ff395f2a1b"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}
