provider "aws" {
    version = "~> 1.11"
    region = "${var.region}"
}

provider "random" {
    version = "~> 1.1"
}
