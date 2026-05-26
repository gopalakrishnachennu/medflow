variable "project_name" {
  type = string
}

variable "services" {
  type = list(string)
}

variable "retained_image_count" {
  type    = number
  default = 30
}
