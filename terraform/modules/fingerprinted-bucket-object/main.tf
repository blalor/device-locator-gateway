resource "random_pet" "object_key" {
    length = 3

    keepers = {
        package_fingerprint = "${md5(file("${var.package_path}"))}"
    }
}

## lambda doesn't re-read a bucket object if it changes
resource "aws_s3_bucket_object" "package" {
    bucket = "${var.bucket}"
    key = "${var.path_prefix}/${random_pet.object_key.id}.zip"

    source = "${var.package_path}"
    etag = "${random_pet.object_key.keepers.package_fingerprint}"
}
