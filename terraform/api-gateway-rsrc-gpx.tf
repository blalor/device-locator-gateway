## /gpx
resource "aws_api_gateway_resource" "gpx" {
    rest_api_id = "${local.rest_api_id}"

    parent_id = "${aws_api_gateway_rest_api.device_locator.root_resource_id}"
    path_part = "gpx"
}

## /gpx/{device_id+}
resource "aws_api_gateway_resource" "gpx_device" {
    rest_api_id = "${local.rest_api_id}"

    parent_id = "${aws_api_gateway_resource.gpx.id}"
    path_part = "{device_id+}"
}

## GET /gpx/{device_id+}
resource "aws_api_gateway_method" "gpx_device" {
    rest_api_id = "${local.rest_api_id}"

    resource_id = "${aws_api_gateway_resource.gpx_device.id}"
    http_method = "GET"
    authorization = "NONE"
}

## log ALL THE THINGS
resource "aws_api_gateway_method_settings" "gpx_device" {
    rest_api_id = "${local.rest_api_id}"
    stage_name = "${aws_api_gateway_deployment.device_locator.stage_name}"
    method_path = "${aws_api_gateway_resource.gpx_device.path_part}/${aws_api_gateway_method.gpx_device.http_method}"

    settings {
        logging_level = "INFO"
        data_trace_enabled = true
    }
}

resource "aws_api_gateway_integration" "gpx_device" {
    rest_api_id = "${local.rest_api_id}"

    resource_id = "${aws_api_gateway_resource.gpx_device.id}"
    http_method = "${aws_api_gateway_method.gpx_device.http_method}"

    type = "AWS_PROXY"
    uri = "${module.gpx.invoke_arn}"
    integration_http_method = "POST"
}
