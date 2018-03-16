variable "region" {
    type = "string"
    description = "aws region"
    default = "us-east-1"
}

variable "old_location_target_endpoint" {
    type = "string"
    description = "old /record_location endpoint to receive updates"
}

variable "dark_sky_api_key" {
    type = "string"
    description = "api key for Dark Sky"
}

variable "opencage_api_key" {
    type = "string"
    description = "api key for OpenCage"
}

variable "inreach_feed_url" {
    type = "string"
    description = "URL of MapShare feed; like https://inreach.garmin.com/feed/Share/your-feed"
}

variable "inreach_feed_password" {
    type = "string"
    description = "password for MapShare feed"
}

variable "inreach_device_id" {
    type = "string"
    description = "device id to use for new inReach points"
}

variable "inreach_poll_rate" {
    type = "string"
    description = "how often to check for updates"
}
