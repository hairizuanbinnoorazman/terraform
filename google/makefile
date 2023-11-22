gcp_id=$(shell gcloud config get project)
components?=[]
add_bastion?=false

plan:
	TF_VAR_gcp_project_id=$(gcp_id) terraform plan -out=initial.plan -var 'components=$(components)' -var 'enable_bastion=$(add_bastion)'

destroy:
	TF_VAR_gcp_project_id=$(gcp_id) terraform plan -out=destroy.plan -destroy