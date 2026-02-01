output "vm_count" {
  value       = var.high_availability ? 3 : 1
  description = "Number of VMs required for the environment."
}

output "network_configuration" {
  value = (
    var.environment == "prod"
    ? "Production Network - Full Scale"
    : "Development/Staging Network - Limited Scale"
  )
  description = "Network configuration based on environment."
}

output "ha_status_message" {
  value = (
    var.high_availability
    ? "High availability is enabled - multiple VMs are needed."
    : "High availability is disabled - a single VM is sufficient."
  )
  description = "HA status message."
}
locals {
  subnets = (
    var.high_availability
    ? ["subnet-a", "subnet-b", "subnet-c"]
    : ["subnet-a"]
  )

  services = var.create_database ? ["web", "api", "database"] : ["web", "api"]
}

output "mock_subnet_list" {
  value       = [for subnet in local.subnets : "Configured ${subnet}"]
  description = "Mocked list of subnets."
}

output "mock_database_creation" {
  value       = var.create_database ? "A mock database will be created for this environment." : "No database needed for this environment."
  description = "Mock DB creation decision"
}

output "mock_services_list" {
  value       = [for s in local.services : "Configured ${s} service"]
  description = "Mocked list of services based on create_database"
}

