module "gpx" {
    source = "./modules/functions/gpx"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/gpx.zip"

    # The /*/* portion grants access from any method on any resource
    # within the API Gateway "REST API".
    api_gateway_exec_arn = "${aws_api_gateway_deployment.device_locator.execution_arn}/*/*"

    table_arn = "${aws_dynamodb_table.device_locator.arn}"
    table_name = "${aws_dynamodb_table.device_locator.name}"

    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
