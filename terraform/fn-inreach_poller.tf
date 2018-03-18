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

module "inreach_poller" {
    source = "./modules/functions/inreach-poller"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/inreach-poller.zip"

    feed_url      = "${var.inreach_feed_url}"
    feed_password = "${var.inreach_feed_password}"
    device_id     = "${var.inreach_device_id}"
    poll_rate     = "${var.inreach_poll_rate}"

    topic_arn = "${aws_sns_topic.device_locator.arn}"
    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
