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

variable "topic" {
    type = "string"
    description = "ARN of topic for publishing device location updates"
}

variable "dead_letter_queue" {
    type = "string"
    description = "ARN for dead letter queue for lambda function"
}

locals {
    fn_name = "device-locator"
}
