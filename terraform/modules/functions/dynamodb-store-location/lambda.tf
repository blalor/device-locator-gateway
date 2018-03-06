resource "aws_lambda_function" "fn" {
    function_name = "${local.fn_name}"

    role = "${aws_iam_role.lambda.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${module.fingerprint_publish_old_location.bucket}"
    s3_key    = "${module.fingerprint_publish_old_location.object}"

    handler = "lambda.handler"

    environment {
        variables = {
            "table_name" = "${var.table}"
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
