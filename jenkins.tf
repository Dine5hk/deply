resource "null_resource" "trigger_jenkins_build" {
  count = 12

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "http://jenkins-server/job/your-job-name/buildWithParameters?token=your-token&server=${aws_instance.lc_server[count.index].private_ip}"
    EOT
  }
  depends_on = [aws_instance.lc_server]
}