resource "null_resource" "provision_apache" {
  depends_on = [
    aws_instance.vm,
    time_sleep.wait_for_ip
  ]

  triggers = {
    instance_id = aws_instance.vm.id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = aws_instance.vm.public_ip
    private_key = file("~/.ssh/lab103")
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y install httpd",
      "sudo mkdir -p /var/www/html",
      "echo '<h1>Welcome to Lab 103</h1>' | sudo tee /var/www/html/welcome.html",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
  }
}
