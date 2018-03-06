output "bucket" {
    value = "${var.bucket}"
}

output "object" {
    value = "${aws_s3_bucket_object.package.id}"
}
