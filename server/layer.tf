data "external" "pip_install" {
  program = ["bash", "layer.sh"]
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = "package"
  output_path = "spotipy.zip"
  depends_on  = [data.external.pip_install]
}

resource "aws_lambda_layer_version" "spotipy" {
  filename            = "spotipy.zip"
  layer_name          = "spotipy"
  #source_code_hash    = data.archive_file.package.output_base64sha256
  compatible_runtimes = ["python3.8"]
}
