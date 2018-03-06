module "fingerprint_publish_old_location" {
    source = "../../fingerprinted-bucket-object"

    bucket = "${var.bucket}"
    package_path = "${var.package_path}"
}
