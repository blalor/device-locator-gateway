resource "aws_api_gateway_rest_api" "device_locator" {
    name = "DeviceLocator"
    description = "DeviceLocator gateway"
}

locals {
    rest_api_id = "${aws_api_gateway_rest_api.device_locator.id}"
}

resource "random_pet" "deployment_trigger" {
    length = 3

    ## https://github.com/hashicorp/terraform/issues/6613
    ## all the things that should trigger a new deployment
    keepers = {
        resource_proxy_path = "${aws_api_gateway_resource.proxy.path_part}"

        gw_meth_proxy_method = "${aws_api_gateway_method.proxy.http_method}"
        gw_meth_proxy_rsrc   = "${aws_api_gateway_method.proxy.resource_id}"
        gw_meth_proxy_auth   = "${aws_api_gateway_method.proxy.authorization}"

        gw_int_lambda_int_meth = "${aws_api_gateway_integration.lambda.integration_http_method}"

        gw_meth_gpx_method = "${aws_api_gateway_method.gpx_device.http_method}"
        gw_meth_gpx_rsrc   = "${aws_api_gateway_method.gpx_device.resource_id}"
        gw_meth_gpx_auth   = "${aws_api_gateway_method.gpx_device.authorization}"

        gw_int_gpx_int_meth = "${aws_api_gateway_integration.gpx_device.integration_http_method}"
    }
}

resource "aws_api_gateway_deployment" "device_locator" {
    depends_on = [
        "aws_api_gateway_integration.lambda",
        "aws_api_gateway_integration.gpx_device",
    ]

    rest_api_id = "${local.rest_api_id}"

    stage_name = "prod"
    stage_description = "${random_pet.deployment_trigger.id}"
}
