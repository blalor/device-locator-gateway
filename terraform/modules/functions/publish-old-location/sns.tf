## subscription for messages to be sent to the old brianandsarah.us endpoint
resource "aws_sns_topic_subscription" "brianandsarah" {
    topic_arn = "${var.topic}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.fn.arn}"
}
