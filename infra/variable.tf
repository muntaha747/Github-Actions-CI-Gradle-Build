variable "image_uri" {
  description = "ECR Image URI"
  type        = string
  default     = "799619129003.dkr.ecr.ca-central-1.amazonaws.com/github-actions-ci-gradle-build:ec7142a"
}

variable "app_name" {
  description = "App Name (no underscores, max ~20 chars recommended)"
  type        = string
  default     = "gradle-hello-app"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-08005b99ec30fa78b"
}

variable "subnet01_ID" {
  description = "Public Subnet 1"
  type        = string
  default     = "subnet-0de356ec63a88b841"
}

variable "subnet02_ID" {
  description = "Public Subnet 2"
  type        = string
  default     = "subnet-02b35e6262141b0f7"
}


variable "image_uri_001" {
  description = "Full ECR image URI"
  type        = string
  default     = "dummy"
}
