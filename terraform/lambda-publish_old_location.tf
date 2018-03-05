locals {
    publish_old_location_package_path = "${path.module}/../stage/publish-old-location.zip"
}

resource "random_pet" "publish_old_location" {
    length = 3

    keepers = {
        publish_old_location_package_fingerprint = "${md5(file("${local.publish_old_location_package_path}"))}"
    }
}

## lambda doesn't re-read a bucket object if it changes
resource "aws_s3_bucket_object" "lambda_publish_old_location" {
    bucket = "${aws_s3_bucket.lambda_functions.id}"
    key = "functions/${random_pet.publish_old_location.id}.zip"

    source = "${local.publish_old_location_package_path}"
    etag = "${random_pet.publish_old_location.keepers.publish_old_location_package_fingerprint}"
}

resource "aws_lambda_function" "publish_old_location" {
    function_name = "publish-old-location"

    role = "${aws_iam_role.lambda_execution_publish_old_location.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${aws_s3_bucket_object.lambda_publish_old_location.bucket}"
    s3_key    = "${aws_s3_bucket_object.lambda_publish_old_location.id}"

    handler = "lambda.handler"

    environment {
        variables = {
            "target_endpoint" = "${var.old_location_target_endpoint}"
        }
    }

    dead_letter_config {
        target_arn = "${aws_sqs_queue.lambda_dead_letter.arn}"
    }
}
