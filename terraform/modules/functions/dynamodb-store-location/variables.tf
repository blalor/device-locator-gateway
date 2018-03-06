variable "bucket" {
    type = "string"
    description = "bucket where deployment package is stored"
}

variable "package_path" {
    type = "string"
    description = "path to the deployment package"
}

variable "table" {
    type = "string"
    description = "dynamodb table name"
}

variable "topic" {
    type = "string"
    description = "ARN of topic for subscription to device location updates"
}

variable "dead_letter_queue" {
    type = "string"
    description = "ARN for dead letter queue for lambda function"
}

locals {
    fn_name = "dynamodb-store-location"
}
