resource "aws_s3_bucket" "lambda_functions" {
    bucket_prefix = "lambda-functions-"
}

locals {
    device_locator_package_path = "${path.module}/../stage/device-locator.zip"
}

resource "random_id" "bucket_key" {
    byte_length = 8

    keepers = {
        device_locator_package_fingerprint = "${md5(file("${local.device_locator_package_path}"))}"
    }
}

## lambda doesn't re-read a bucket object if it changes
resource "aws_s3_bucket_object" "lambda_device_locator" {
    bucket = "${aws_s3_bucket.lambda_functions.id}"
    key = "functions/${random_id.bucket_key.hex}.zip"

    source = "${local.device_locator_package_path}"
    etag = "${random_id.bucket_key.keepers.device_locator_package_fingerprint}"
}
