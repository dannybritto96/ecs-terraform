output "apigw_addr" {
    value = aws_apigatewayv2_stage.example.invoke_url
}