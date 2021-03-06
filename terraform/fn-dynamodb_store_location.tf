variable "dark_sky_api_key" {
    type = "string"
    description = "api key for Dark Sky"
}

variable "opencage_api_key" {
    type = "string"
    description = "api key for OpenCage"
}

module "dynamodb_store_location" {
    source = "./modules/functions/dynamodb-store-location"

    bucket = "${aws_s3_bucket.lambda_functions.id}"
    package_path = "${path.module}/../stage/dynamodb-store-location.zip"

    table_arn = "${aws_dynamodb_table.device_locator.arn}"
    table_name = "${aws_dynamodb_table.device_locator.name}"

    dark_sky_api_key = "${var.dark_sky_api_key}"
    opencage_api_key = "${var.opencage_api_key}"

    topic = "${aws_sns_topic.device_locator.arn}"
    dead_letter_queue = "${aws_sqs_queue.lambda_dead_letter.arn}"
}
