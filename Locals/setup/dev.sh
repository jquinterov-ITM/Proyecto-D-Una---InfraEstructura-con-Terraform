#!/bin/bash
export TF_WORKSPACE="dev"
 
# Set workspace for CI/CD
# terraform workspace select $TF_WORKSPACE || terraform workspace new $TF_WORKSPACE
 
# Global Variables
export TF_VAR_aws_region="us-east-1"
#IP pública: => (Invoke-RestMethod -Uri "https://api.ipify.org")
export TF_VAR_my_ip="201.233.77.14/32"
export TF_VAR_aws_profile="Seminario2"
 
# Network and Compute Variables
export TF_VAR_key_name="testKey"
export TF_VAR_master_type="t3.medium"
export TF_VAR_worker_type="t3.large"
export TF_VAR_vpc_cidr="172.20.0.0/23"
export TF_VAR_pub_subnets='["172.20.0.0/26", "172.20.0.64/26"]'
export TF_VAR_priv_subnets='["172.20.0.128/26", "172.20.0.192/26"]'
 
# K3S Secret Variables
export TF_VAR_k3s_token="K3s-Secret-2026-Token"
 
# Persistence Variables
export TF_VAR_db_instance_class="db.t3.micro"
export TF_VAR_db_allocated_storage=20
 
# Persistence Secret Variables
export TF_VAR_db_password="12345678"
 
echo "Context switched to DEV"
 