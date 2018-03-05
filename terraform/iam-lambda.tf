data "aws_iam_policy_document" "assume_role_lambda" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

###
### device-locator
###
data "aws_iam_policy_document" "lambda_role_policy_device_locator" {
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

resource "aws_iam_role" "lambda_execution_device_locator" {
    path = "/service-role/"
    name = "LambdaDeviceLocator"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_lambda.json}"
}

resource "aws_iam_role_policy" "lambda_execution_device_locator" {
    role = "${aws_iam_role.lambda_execution_device_locator.id}"
    policy = "${data.aws_iam_policy_document.lambda_role_policy_device_locator.json}"
}

###
### publish-old-location
###
data "aws_iam_policy_document" "lambda_role_policy_publish_old_location" {
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

resource "aws_iam_role" "lambda_execution_publish_old_location" {
    path = "/service-role/"
    name = "LambdaPublishOldLocation"
    assume_role_policy = "${data.aws_iam_policy_document.assume_role_lambda.json}"
}

resource "aws_iam_role_policy" "lambda_execution_publish_old_location" {
    role = "${aws_iam_role.lambda_execution_publish_old_location.id}"
    policy = "${data.aws_iam_policy_document.lambda_role_policy_publish_old_location.json}"
}
