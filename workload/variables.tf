# Service account that Terraform impersonates when applying this stack (created manually — see README §6.1).
variable "tf_runner_sa" {
  description = "Email of the TF Runner SA dedicated to the workload stack"
  type        = string
}
