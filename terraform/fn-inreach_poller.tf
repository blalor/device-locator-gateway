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
