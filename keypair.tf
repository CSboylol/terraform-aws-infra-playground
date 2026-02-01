resource "aws_key_pair" "lab103" {
  key_name   = "lab103-key"
  public_key = file("~/.ssh/lab103.pub")
}
