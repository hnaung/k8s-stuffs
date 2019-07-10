variable "db_identifier" {
  default = "prod-rds"
}

variable "db_instance" {
  default = "db.t2.medium"
}

variable "rds_subnet1" {
  default = "subnet-014d9aeecd49010d4"
}

variable "rds_subnet2" {
  default = "subnet-0289b469af699ca4c"
}

variable "rds_subnet3" {
  default = "subnet-0861d68941e76360b"
}
variable "vpc_id" {
  default = "vpc-0dd6d3d2ffd7cffaf"
}

variable "allocated_storage" {
  description = "The allocated storage in gibibytes."
  default     = "20"
}

variable "db_username" {
  description = "Username for the master DB user. Leave empty to generate."
  default     = "admin"
}

variable "db_password" {
  description = "Password for the master DB user. Leave empty to generate."
  default     = "gplus-prod2020"
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created."
  default     = "proddb"
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = 3
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled."
  default     = "05:00-07:00"
}

variable "instance_type" {
  description = "The instance type of the RDS instance"
  default     = "db.t2.small"
}

variable "engine_version" {
  description = "MySQL version. Default is 8.0"
  default     = "8.0.15"
}