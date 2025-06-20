# ----------------------
# DYNAMODB TABLE
# ----------------------
resource "aws_dynamodb_table" "short_links" {
    name           = "url-shortener"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "code"

    attribute {
        name = "code"
        type = "S"
    }
}