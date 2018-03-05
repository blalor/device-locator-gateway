locals {
    dynamodb_store_location_package_path = "${path.module}/../stage/dynamodb-store-location.zip"
}

resource "random_pet" "dynamodb_store_location" {
    length = 3

    keepers = {
        dynamodb_store_location_package_fingerprint = "${md5(file("${local.dynamodb_store_location_package_path}"))}"
    }
}

## lambda doesn't re-read a bucket object if it changes
resource "aws_s3_bucket_object" "lambda_dynamodb_store_location" {
    bucket = "${aws_s3_bucket.lambda_functions.id}"
    key = "functions/${random_pet.dynamodb_store_location.id}.zip"

    source = "${local.dynamodb_store_location_package_path}"
    etag = "${random_pet.dynamodb_store_location.keepers.dynamodb_store_location_package_fingerprint}"
}

resource "aws_lambda_function" "dynamodb_store_location" {
    function_name = "dynamodb-store-location"

    role = "${aws_iam_role.lambda_execution_dynamodb_store_location.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${aws_s3_bucket_object.lambda_dynamodb_store_location.bucket}"
    s3_key    = "${aws_s3_bucket_object.lambda_dynamodb_store_location.id}"

    handler = "lambda.handler"

    environment {
        variables = {
            "table_name" = "${aws_dynamodb_table.device_locator.name}"
        }
    }

    dead_letter_config {
        target_arn = "${aws_sqs_queue.lambda_dead_letter.arn}"
    }
}
