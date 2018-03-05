locals {
    device_locator_package_path = "${path.module}/../stage/device-locator.zip"
}

resource "random_pet" "device_locator" {
    length = 3

    keepers = {
        device_locator_package_fingerprint = "${md5(file("${local.device_locator_package_path}"))}"
    }
}

## lambda doesn't re-read a bucket object if it changes
resource "aws_s3_bucket_object" "lambda_device_locator" {
    bucket = "${aws_s3_bucket.lambda_functions.id}"
    key = "functions/${random_pet.device_locator.id}.zip"

    source = "${local.device_locator_package_path}"
    etag = "${random_pet.device_locator.keepers.device_locator_package_fingerprint}"
}

resource "aws_lambda_function" "device_locator" {
    function_name = "device-locator" ## api gateway permission doesn't allow "-"

    role = "${aws_iam_role.lambda_execution_device_locator.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${aws_s3_bucket_object.lambda_device_locator.bucket}"
    s3_key    = "${aws_s3_bucket_object.lambda_device_locator.id}"
    handler = "lambda.handler"

    environment {
        variables = {
            "topic_arn" = "${aws_sns_topic.device_locator.arn}"
        }
    }

    dead_letter_config {
        target_arn = "${aws_sqs_queue.lambda_dead_letter.arn}"
    }
}
