## /record_location
resource "aws_api_gateway_resource" "record_location" {
    rest_api_id = "${local.rest_api_id}"

    parent_id = "${aws_api_gateway_rest_api.device_locator.root_resource_id}"
    path_part = "record_location"
}

## /record_location/{device_id+}
resource "aws_api_gateway_resource" "proxy" {
    rest_api_id = "${local.rest_api_id}"

    parent_id = "${aws_api_gateway_resource.record_location.id}"
    path_part = "{device_id+}"
}

## GET /record_location/{device_id+} (but "ANY" instead)
resource "aws_api_gateway_method" "proxy" {
    rest_api_id = "${local.rest_api_id}"

    resource_id = "${aws_api_gateway_resource.proxy.id}"
    http_method = "ANY"
    authorization = "NONE"
}

## https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html
resource "aws_api_gateway_integration" "lambda" {
    rest_api_id = "${local.rest_api_id}"
    resource_id = "${aws_api_gateway_resource.proxy.id}"
    http_method = "${aws_api_gateway_method.proxy.http_method}"

    type = "AWS_PROXY"
    uri = "${module.device_locator.invoke_arn}"
    integration_http_method = "ANY"
}
