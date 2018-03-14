variable "bucket" {
    type = "string"
    description = "bucket where deployment package is stored"
}

variable "package_path" {
    type = "string"
    description = "path to the deployment package"
}

variable "api_gateway_exec_arn" {
    type = "string"
    description = "full execution arn for the api gateway"
}

variable "table_arn" {
    type = "string"
    description = "dynamodb table arn"
}

variable "table_name" {
    type = "string"
    description = "dynamodb table name"
}

variable "dead_letter_queue" {
    type = "string"
    description = "ARN for dead letter queue for lambda function"
}

locals {
    fn_name = "gpx"
}
