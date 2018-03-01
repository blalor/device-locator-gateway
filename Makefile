## fully-qualified path to this Makefile
MKFILE_PATH := $(realpath $(lastword $(MAKEFILE_LIST)))
## fully-qualified path to the current directory
CURRENT_DIR := $(patsubst %/,%,$(dir $(MKFILE_PATH)))

stage:
	mkdir -p $@

stage/device-locator.zip: $(shell find functions/device-locator -type f) | stage
	(cd functions/device-locator && zip -r - .) > $@

## terraform init
init: terraform/.terraform
terraform/.terraform:
	cd terraform && terraform init

## terraform plan
plan: $(CURRENT_DIR)/stage/terraform.plan
$(CURRENT_DIR)/stage/terraform.plan: | stage
	cd terraform && terraform plan -out $@

## terraform apply
apply: stage/device-locator.zip plan
	cd terraform && terraform apply $(CURRENT_DIR)/stage/terraform.plan
	@rm -f $(CURRENT_DIR)/stage/terraform.plan
