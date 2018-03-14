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
            "table_name" = "${var.table_name}"
        }
    }

    dead_letter_config {
        target_arn = "${var.dead_letter_queue}"
    }
}

resource "aws_lambda_permission" "api_gateway" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.fn.arn}"
    principal = "apigateway.amazonaws.com"

    source_arn = "${var.api_gateway_exec_arn}"
}
