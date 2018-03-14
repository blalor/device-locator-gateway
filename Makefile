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

## don't delete intermediate files
.PRECIOUS: stage/%/_ve
stage/%/_ve: | stage
	virtualenv $@

stage/%/_ve/requirements.met: functions/%/requirements.txt | stage/%/_ve
	sh -c '. $|/bin/activate && pip install -q -r $<'
	touch $@

## https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html
##stage/%.zip: stage/%/_ve/requirements.met
##	rm -f $@
##	(cd $(dir $<)/lib/python2.7/site-packages && zip -r $@ .)
##	(cd $(patsubst stage/%/_ve/requirements.met,functions/%,$<) && zip -r $@ .)

stage/device-locator.zip: $(shell find functions/device-locator -type f) | stage
	rm -f $@
	(cd functions/device-locator && zip -9r $(CURRENT_DIR)/$@ .)

stage/publish-old-location.zip: $(shell find functions/publish-old-location -type f) | stage
	rm -f $@
	(cd functions/publish-old-location && zip -9r $(CURRENT_DIR)/$@ .)

stage/dynamodb-store-location.zip: $(shell find functions/dynamodb-store-location -type f ) stage/dynamodb-store-location/_ve/requirements.met
	rm -f $@
	(cd stage/dynamodb-store-location/_ve/lib/python2.7/site-packages && zip -9qr $(CURRENT_DIR)/$@ .)
	(cd functions/dynamodb-store-location && zip -9r $(CURRENT_DIR)/$@ .)

stage/gpx.zip: $(shell find functions/gpx -type f ) stage/gpx/_ve/requirements.met
	rm -f $@
	(cd stage/gpx/_ve/lib/python2.7/site-packages && zip -9qr $(CURRENT_DIR)/$@ .)
	(cd functions/gpx && zip -9r $(CURRENT_DIR)/$@ .)

PACKAGES := \
	stage/device-locator.zip \
	stage/publish-old-location.zip \
	stage/dynamodb-store-location.zip \
	stage/gpx.zip

## terraform init
.PHONY: init
init: terraform/.terraform
terraform/.terraform:
	cd terraform && terraform init

## terraform plan
.PHONY: plan
plan: $(PLANFILE) | terraform/.terraform
$(PLANFILE): $(TF_SOURCES) $(PACKAGES)
	cd terraform && terraform plan -out $@

## terraform apply
.PHONY: apply
apply: $(PLANFILE)
	cd terraform && terraform apply $(PLANFILE)
	@rm -f $(PLANFILE)

.PHONY: clean
clean:
	rm -rf stage
