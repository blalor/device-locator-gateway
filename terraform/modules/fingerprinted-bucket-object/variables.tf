variable "bucket" {
    type = "string"
    description = "the bucket where deployment packages will be uploaded"
}

variable "path_prefix" {
    type = "string"
    description = "path prefix for objects"
    default = "functions"
}

variable "package_path" {
    type = "string"
    description = "path to the deployment package"
}
