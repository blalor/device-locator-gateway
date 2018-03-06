## topic for messages ingested by the device-locator function
resource "aws_sns_topic" "device_locator" {
    name = "device-locator"
}
