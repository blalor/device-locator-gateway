terraform {
    required_version = ">= 0.11.8"

    backend "s3" {
        # bucket = "…" ## partial
        # region = "…" ## partial
        key = "device-locator-gateway/terraform.tfstate"
    }
}
