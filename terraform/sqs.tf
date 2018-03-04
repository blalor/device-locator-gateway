resource "aws_sqs_queue" "lambda_dead_letter" {
    name = "lambda-dead-letter"
}
