data "aws_iam_policy_document" "assume" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "exec" {
    statement {
        sid = "deadletter"

        actions = ["sqs:SendMessage"]
        resources = [
            "${var.dead_letter_queue}",
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

resource "aws_iam_role" "lambda" {
    path = "/service-role/"
    name = "LambdaPublishOldLocation"
    description = "Permissions for the publish-old-location function"
    assume_role_policy = "${data.aws_iam_policy_document.assume.json}"
}

resource "aws_iam_role_policy" "lambda" {
    name = "${aws_iam_role.lambda.name}"
    role = "${aws_iam_role.lambda.id}"
    policy = "${data.aws_iam_policy_document.exec.json}"
}

