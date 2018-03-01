resource "aws_sqs_queue" "device_locator_wx" {
    name = "device-locator-wx"
}

resource "aws_sns_topic_subscription" "device_locator_wx" {
    topic_arn = "${aws_sns_topic.device_locator.arn}"
    protocol = "sqs"
    endpoint = "${aws_sqs_queue.device_locator_wx.arn}"
}
