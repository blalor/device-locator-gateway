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
    }
}

resource "aws_api_gateway_deployment" "device_locator" {
    depends_on = [
        "aws_api_gateway_integration.lambda",
    ]

    rest_api_id = "${local.rest_api_id}"

    stage_name = "prod"
    stage_description = "${random_pet.deployment_trigger.id}"
}
