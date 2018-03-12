resource "aws_api_gateway_rest_api" "device_locator" {
    name = "DeviceLocator"
    description = "DeviceLocator gateway"
}

## /record_location
resource "aws_api_gateway_resource" "record_location" {
    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"

    parent_id = "${aws_api_gateway_rest_api.device_locator.root_resource_id}"
    path_part = "record_location"
}

## /record_location/{device_id+}
resource "aws_api_gateway_resource" "proxy" {
    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"

    parent_id = "${aws_api_gateway_resource.record_location.id}"
    path_part = "{device_id+}"
}

## GET /record_location/{device_id+} (but "ANY" instead)
resource "aws_api_gateway_method" "proxy" {
    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"

    resource_id = "${aws_api_gateway_resource.proxy.id}"
    http_method = "ANY"
    authorization = "NONE"
}

## https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html
resource "aws_api_gateway_integration" "lambda" {
    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"
    resource_id = "${aws_api_gateway_resource.proxy.id}"
    http_method = "${aws_api_gateway_method.proxy.http_method}"

    type = "AWS_PROXY"
    uri = "${module.device_locator.invoke_arn}"
    integration_http_method = "ANY"
}

resource "random_pet" "deployment_trigger" {
    length = 3

    ## https://github.com/hashicorp/terraform/issues/6613
    ## all the things that should trigger a new deployment
    keepers = {
        resource_proxy_path = "${aws_api_gateway_resource.proxy.path_part}"
    }
}

resource "aws_api_gateway_deployment" "device_locator" {
    depends_on = [
        "aws_api_gateway_integration.lambda"
    ]

    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"
    stage_name = "prod"
    stage_description = "${random_pet.deployment_trigger.id}"
}
