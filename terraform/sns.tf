## topic for messages ingested by the device-locator function
resource "aws_sns_topic" "device_locator" {
    name = "device-locator"
}

###
### publish-old-location
###

## subscription for messages to be sent to the old brianandsarah.us endpoint
resource "aws_sns_topic_subscription" "brianandsarah" {
    topic_arn = "${aws_sns_topic.device_locator.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.publish_old_location.arn}"
}

resource "aws_lambda_permission" "sns_publish_old_location" {
    statement_id = "AllowSNSInvokeOldLocation"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.publish_old_location.function_name}"

    principal = "sns.amazonaws.com"

    ## arg! source_arn is that of the TOPIC, not the SUBSCRIPTION!
    source_arn = "${aws_sns_topic.device_locator.arn}"
}

###
### dynamodb-store-location
###

## subscription for messages to be stored in dynamodb
resource "aws_sns_topic_subscription" "dynamodb" {
    topic_arn = "${aws_sns_topic.device_locator.arn}"
    protocol = "lambda"
    endpoint = "${aws_lambda_function.dynamodb_store_location.arn}"
}

resource "aws_lambda_permission" "sns_dynamodb_store_location" {
    statement_id = "AllowSNSInvokeOldLocation"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.dynamodb_store_location.function_name}"

    principal = "sns.amazonaws.com"

    ## arg! source_arn is that of the TOPIC, not the SUBSCRIPTION!
    source_arn = "${aws_sns_topic.device_locator.arn}"
}
