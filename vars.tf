variable "main_vpc_cidr" {
    default = "10.0.0.0/16"
}
variable "public_subnet1" {
    default = "10.0.0.128/26"
}
variable "public_subnet2" {
    default = "10.0.1.128/26"
}
variable "private_subnet1" {
    default = "10.0.0.192/26"
}
variable "private_subnet2" {
    default = "10.0.1.192/26"
}
