variable "bucket" {
    type = "string"
    description = "bucket where deployment package is stored"
}

variable "package_path" {
    type = "string"
    description = "path to the deployment package"
}

variable "topic_arn" {
    type = "string"
    description = "ARN of topic for publishing device location updates"
}

variable "feed_url" {
    type = "string"
    description = "URL of MapShare feed; like https://inreach.garmin.com/feed/Share/your-feed"
}

variable "feed_password" {
    type = "string"
    description = "password for MapShare feed"
}

variable "device_id" {
    type = "string"
    description = "device id to use for new points"
}

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#RateExpressions
variable "poll_rate" {
    type = "string"
    description = "how often to trigger the poller; default is sufficient for 10m update rate"
}

variable "dead_letter_queue" {
    type = "string"
    description = "ARN for dead letter queue for lambda function"
}

locals {
    fn_name = "inreach-poller"
}
