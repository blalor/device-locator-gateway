resource "aws_lambda_function" "fn" {
    function_name = "${local.fn_name}"

    role = "${aws_iam_role.lambda.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${module.fingerprinted_bucket_object.bucket}"
    s3_key    = "${module.fingerprinted_bucket_object.object}"

    handler = "lambda.handler"

    environment {
        variables = {
            "topic_arn"     = "${var.topic_arn}"
            "feed_url"      = "${var.feed_url}"
            "device_id"     = "${var.device_id}"
            "feed_password" = "${var.feed_password}"
        }
    }

    dead_letter_config {
        target_arn = "${var.dead_letter_queue}"
    }
}

resource "aws_lambda_permission" "cloudwatch" {
    statement_id = "AllowCloudwatchInvoke"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.fn.function_name}"
    principal = "events.amazonaws.com"

    source_arn = "${aws_cloudwatch_event_rule.trigger_inreach_poller.arn}"
}
