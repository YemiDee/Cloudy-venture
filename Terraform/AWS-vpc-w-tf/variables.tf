variable "ami" {
  default = "ami-0b0af3577fe5e3532"
}

variable "pub_cidr" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance-ami" {
  default = "t2.micro"
}

variable "prj-vpc-key" {
  default     = "~/OneDrive/Academia/Cloud_comput/Key_pairs/proj-vpc-key.pub"
  description = "keypair path"
}