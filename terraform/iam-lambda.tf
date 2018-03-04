data "aws_iam_policy_document" "assume_role_lambda" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "lambda_role_policy" {
    statement {
        sid = "pubbit"

        actions = ["sns:Publish"]
        resources = [
            "${aws_sns_topic.device_locator.arn}",
        ]
    }

    statement {
        sid = "deadletter"

        actions = ["sqs:SendMessage"]
        resources = [
            "${aws_sqs_queue.lambda_dead_letter.arn}",
        ]
    }

    ## allow logging
    statement {
        sid = "loggit"

        actions = [
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
        ]

        resources = ["*"]
    }
}

resource "aws_iam_role" "lambda_execution" {
    path = "/service-role/"
    name = "LambdaDeviceLocator"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_lambda.json}"
}

resource "aws_iam_role_policy" "lambda_execution" {
    role = "${aws_iam_role.lambda_execution.id}"
    policy = "${data.aws_iam_policy_document.lambda_role_policy.json}"
}
