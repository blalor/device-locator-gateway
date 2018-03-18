variable "old_location_target_endpoint" {
    type = "string"
    description = "old /record_location endpoint to receive updates"
}

module "publish_old_location" {
    source = "modules/functions/publish-old-location"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/publish-old-location.zip"

    old_location_target_endpoint = "${var.old_location_target_endpoint}"

    topic = "${aws_sns_topic.device_locator.arn}"
    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
