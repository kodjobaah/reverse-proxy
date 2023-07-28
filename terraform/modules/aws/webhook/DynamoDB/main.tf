

resource "aws_dynamodb_table" "webhook-proxy" {
  name           = "WebhookProxy"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Proxy"
  range_key      = "Environment"

  attribute {
    name = "Proxy"
    type = "S"
  }

  attribute {
    name = "Environment"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  lifecycle {
    ignore_changes = [
      ttl
    ]
  }

}