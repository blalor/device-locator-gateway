resource "aws_cloudwatch_event_rule" "trigger_inreach_poller" {
    name = "trigger-inreach-poller"
    description = "periodically triggers the inReach poller Lambda fn"

    schedule_expression = "rate(${var.poll_rate})"
}

resource "aws_cloudwatch_event_target" "name" {
    rule = "${aws_cloudwatch_event_rule.trigger_inreach_poller.name}"
    target_id = "trigger-inreach-poller"
    arn = "${aws_lambda_function.fn.arn}"
}
