output "base_url" {
    value = "${aws_api_gateway_deployment.device_locator.invoke_url}"
}
