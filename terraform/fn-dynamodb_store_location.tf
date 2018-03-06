module "dynamodb_store_location" {
    source = "modules/functions/dynamodb-store-location"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/dynamodb-store-location.zip"

    table = "${aws_dynamodb_table.device_locator.arn}"
    topic = "${aws_sns_topic.device_locator.arn}"
    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
