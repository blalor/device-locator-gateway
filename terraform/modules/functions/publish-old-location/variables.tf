variable "bucket" {
    type = "string"
    description = "bucket where deployment package is stored"
}

variable "package_path" {
    type = "string"
    description = "path to the deployment package"
}

variable "old_location_target_endpoint" {
    type = "string"
    description = "old /record_location endpoint to receive updates"
}

variable "topic" {
    type = "string"
    description = "ARN of topic for subscription to device location updates"
}

variable "dead_letter_queue" {
    type = "string"
    description = "ARN for dead letter queue for lambda function"
}
