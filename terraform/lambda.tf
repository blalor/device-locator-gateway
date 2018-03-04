resource "aws_lambda_function" "device_locator" {
    function_name = "device-locator" ## api gateway permission doesn't allow "-"

    role = "${aws_iam_role.lambda_execution.arn}"

    runtime = "python2.7"
    timeout = 30

    s3_bucket = "${aws_s3_bucket.lambda_functions.id}"
    s3_key = "${aws_s3_bucket_object.lambda_device_locator.id}"
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
