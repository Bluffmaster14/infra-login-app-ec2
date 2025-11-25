variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0fa3fe0fa7920f68e"
}

variable "instance_type" {
  description = "The Instacne type for EC2 instance"
  type        = string
  default     = "t3.micro"
}