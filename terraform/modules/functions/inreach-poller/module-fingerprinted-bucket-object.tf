module "fingerprinted_bucket_object" {
    source = "../../fingerprinted-bucket-object"

    bucket = "${var.bucket}"
    package_path = "${var.package_path}"
}
