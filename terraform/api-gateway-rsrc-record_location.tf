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
    http_method = "GET"
    authorization = "NONE"
}

## log ALL THE THINGS
resource "aws_api_gateway_method_settings" "proxy" {
    rest_api_id = "${local.rest_api_id}"
    stage_name = "${aws_api_gateway_deployment.device_locator.stage_name}"
    method_path = "${aws_api_gateway_resource.proxy.path_part}/${aws_api_gateway_method.proxy.http_method}"

    settings {
        logging_level = "INFO"
        data_trace_enabled = true
    }
}

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id = "${local.rest_api_id}"

    resource_id = "${aws_api_gateway_resource.proxy.id}"
    http_method = "${aws_api_gateway_method.proxy.http_method}"

    type = "AWS_PROXY"
    uri = "${module.device_locator.invoke_arn}"
    integration_http_method = "POST"
}
