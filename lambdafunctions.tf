
# LAMBDA FUNCTIONS
# ----------------------
resource "aws_lambda_function" "create_link" {
  function_name = "createLink"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "create_link.lambda_handler"
  runtime       = "python3.9"
  filename      = "build/create_link.zip"
  source_code_hash = filebase64sha256("build/create_link.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.short_links.name
    }
  }
}

resource "aws_lambda_function" "redirect" {
  function_name = "redirectLink"
  
  role          = aws_iam_role.lambda_exec_role.arn

  filename      = "build/redirect.zip"  # <-- add this
  source_code_hash = filebase64sha256("build/redirect.zip")  # optional but recommended for tracking changes

  handler       = "redirect.lambda_handler"
  runtime       = "python3.9"
  
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.short_links.name
    }
  }
}
