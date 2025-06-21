output "included_files_debug" {
  value = fileset("${path.module}/modules", "*")
}

output "included_files" {
  value = local.statement_paths
}
