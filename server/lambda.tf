data "archive_file" "spotifyaml" {
  type        = "zip"
  source_file = "spotifyaml-api.py"
  output_path = "spotifyaml.zip"
}

data "aws_iam_policy_document" "spotifyaml_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "spotifyaml_role" {
  name               = "spotifyaml-role-cw9duj53"
  assume_role_policy = data.aws_iam_policy_document.spotifyaml_assume_role_policy.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "logging" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:us-east-2:650179012749:*"]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:us-east-2:650179012749:log-group:/aws/lambda/spotifyaml:*"]
  }
}

data "aws_iam_policy_document" "secrets" {
  statement {
    sid       = "VisualEditor0"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:us-east-2:650179012749:secret:spotifyaml*"]
  }
}

locals {
  policies = [
    data.aws_iam_policy_document.logging.json,
    data.aws_iam_policy_document.secrets.json
  ]
}

resource "aws_iam_policy" "spotifyaml_policies" {
  count = length(local.policies)
  name = [
    "SpotifYAMLogging",
    "GetSpotifYAMLSecrets"
  ][count.index]
  policy = local.policies[count.index]
}

resource "aws_iam_policy_attachment" "spotifyaml_attachments" {
  count = length(local.policies)
  name = [
    "SpotifYAMLogging",
    "GetSpotifYAMLSecrets"
  ][count.index]
  policy_arn = aws_iam_policy.spotifyaml_policies[count.index].arn
  roles      = [aws_iam_role.spotifyaml_role.name]
}

resource "aws_lambda_function" "spotifyaml_backend" {
  filename         = "spotifyaml.zip"
  function_name    = "spotifyaml"
  handler          = "spotifyaml-api.lambda_handler"
  source_code_hash = data.archive_file.spotifyaml.output_base64sha256
  runtime          = "python3.8"
  role             = aws_iam_role.spotifyaml_role.arn
  layers           = [aws_lambda_layer_version.spotipy.arn]
}
