resource "aws_api_gateway_rest_api" "spotifyaml_gateway" {
  name = "spotifyaml_gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

locals {
  actions = [
    "plan"
  ]
}

resource "aws_api_gateway_resource" "spotifyaml_gateway_paths" {
  count       = length(local.actions)
  rest_api_id = aws_api_gateway_rest_api.spotifyaml_gateway.id
  parent_id   = aws_api_gateway_rest_api.spotifyaml_gateway.root_resource_id
  path_part   = local.actions[count.index]
}

resource "aws_api_gateway_method" "spotifyaml_path_methods" {
  count         = length(local.actions)
  rest_api_id   = aws_api_gateway_rest_api.spotifyaml_gateway.id
  resource_id   = aws_api_gateway_resource.spotifyaml_gateway_paths[count.index].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gateway_lambda_integrations" {
  count                   = length(aws_api_gateway_method.spotifyaml_path_methods)
  rest_api_id             = aws_api_gateway_rest_api.spotifyaml_gateway.id
  resource_id             = aws_api_gateway_resource.spotifyaml_gateway_paths[count.index].id
  http_method             = aws_api_gateway_method.spotifyaml_path_methods[count.index].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.spotifyaml_backend.invoke_arn
}

resource "aws_api_gateway_deployment" "spotifyaml" {
  depends_on  = [aws_api_gateway_integration.gateway_lambda_integrations[0]]
  rest_api_id = aws_api_gateway_rest_api.spotifyaml_gateway.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "allow_gateway_invoke_spotifyaml" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spotifyaml_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.spotifyaml_gateway.execution_arn}/*/*"
}
