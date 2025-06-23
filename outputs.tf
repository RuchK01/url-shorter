output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "redirect_route" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/{code}"
}
