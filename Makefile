## fully-qualified path to this Makefile
MKFILE_PATH := $(realpath $(lastword $(MAKEFILE_LIST)))
## fully-qualified path to the current directory
CURRENT_DIR := $(patsubst %/,%,$(dir $(MKFILE_PATH)))

PLANFILE := $(CURRENT_DIR)/stage/terraform.plan
TF_SOURCES := $(shell find terraform -type f ! -name 'terraform.tfstate*' ! -path '*/.terraform/*' )

.PHONY: default
default: plan

stage:
	mkdir -p $@

## https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html
%/.requirements.met: %/requirements.txt
	pip install -t $(dir $<) -r $<
	@touch $@

stage/device-locator.zip: $(shell find functions/device-locator -type f) | stage
	(cd functions/device-locator && zip -r - .) > $@

stage/publish-old-location.zip: $(shell find functions/publish-old-location -type f) | stage
	(cd functions/publish-old-location && zip -r - .) > $@

stage/dynamodb-store-location.zip: $(shell find functions/dynamodb-store-location -type f) functions/dynamodb-store-location/.requirements.met | stage
	(cd functions/dynamodb-store-location && zip -r - .) > $@

.PHONY: package
package: stage/device-locator.zip stage/publish-old-location.zip stage/dynamodb-store-location.zip

## terraform init
.PHONY: init
init: terraform/.terraform
terraform/.terraform:
	cd terraform && terraform init

## terraform plan
.PHONY: plan
plan: $(PLANFILE)
$(PLANFILE): $(TF_SOURCES) stage/device-locator.zip stage/publish-old-location.zip stage/dynamodb-store-location.zip | stage
	cd terraform && terraform plan -out $@

## terraform apply
.PHONY: apply
apply: $(PLANFILE)
	cd terraform && terraform apply $(PLANFILE)
	@rm -f $(CURRENT_DIR)/stage/terraform.plan

.PHONY: clean
clean:
	rm -rfv stage
