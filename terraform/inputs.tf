variable "region" {
    type = "string"
    description = "aws region"
    default = "us-east-1"
}

variable "old_location_target_endpoint" {
    type = "string"
    description = "old /record_location endpoint to receive updates"
}
