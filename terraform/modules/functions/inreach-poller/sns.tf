## subscription for messages to be stored in dynamodb
resource "aws_sns_topic_subscription" "dynamodb" {
    topic_arn = "${var.topic_arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.fn.arn}"
}
