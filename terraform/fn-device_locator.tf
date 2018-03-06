module "device_locator" {
    source = "modules/functions/device-locator"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/device-locator.zip"

    # The /*/* portion grants access from any method on any resource
    # within the API Gateway "REST API".
    api_gateway_exec_arn = "${aws_api_gateway_deployment.device_locator.execution_arn}/*/*"

    topic = "${aws_sns_topic.device_locator.arn}"
    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
