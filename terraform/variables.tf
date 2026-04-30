variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "us-east-1"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  default     = "mindmeld-eks-cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
  type        = string
}
