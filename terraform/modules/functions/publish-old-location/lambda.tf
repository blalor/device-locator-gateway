resource "aws_lambda_function" "fn" {
    function_name = "publish-old-location"

    role = "${aws_iam_role.lambda.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${module.fingerprint_publish_old_location.bucket}"
    s3_key    = "${module.fingerprint_publish_old_location.object}"

    handler = "lambda.handler"

    environment {
        variables = {
            "target_endpoint" = "${var.old_location_target_endpoint}"
        }
    }

    dead_letter_config {
        target_arn = "${var.dead_letter_queue}"
    }
}

resource "aws_lambda_permission" "sns" {
    statement_id = "AllowSNSInvokeOldLocation"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.fn.function_name}"

    principal = "sns.amazonaws.com"

    source_arn = "${var.topic}"
}
