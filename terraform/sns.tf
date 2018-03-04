resource "aws_sns_topic" "device_locator" {
    name = "device-locator"
}

resource "aws_sns_topic_subscription" "requestbin" {
    topic_arn = "${aws_sns_topic.device_locator.arn}"
    protocol = "https"
    endpoint = "https://requestb.in/1kb89qk1"
    endpoint_auto_confirms = true
    raw_message_delivery = true
}
