resource "aws_dynamodb_table" "device_locator" {
    name = "device-locator"

    hash_key = "device_id"
    range_key = "timestamp"

    write_capacity = 1
    read_capacity = 10 # ¯\_(ツ)_/¯ how many units to generate the gpx?

    attribute {
        name = "device_id"
        type = "S"
    }

    attribute {
        name = "timestamp"
        type = "N"
    }
}
