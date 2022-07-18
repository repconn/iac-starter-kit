.SILENT: # do not echo commands as we run them

# if the first argument is "newaws"
ifeq (newaws,$(firstword $(MAKECMDGOALS)))
    # use the rest as arguments for "newaws"
    ACCOUNT_NAME := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    # fail if ACCOUNT_NAME is not defined
    ifndef ACCOUNT_NAME
        $(error ❌ ACCOUNT_NAME is not set)
    endif
    # and turn them into do-nothing targets
    $(eval $(ACCOUNT_NAME):;@:)
# if the first argument is "newgcp"
else ifeq (newgcp,$(firstword $(MAKECMDGOALS)))
    # use the rest as arguments for "newgcp"
    ACCOUNT_NAME := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    # fail if ACCOUNT_NAME is not defined
    ifndef ACCOUNT_NAME
        $(error ❌ ACCOUNT_NAME is not set)
    endif
    # and turn them into do-nothing targets
    $(eval $(ACCOUNT_NAME):;@:)
endif

newaws:
	echo 🧩 Bootstrapping the new AWS account $(ACCOUNT_NAME)
	mkdir -p live/aws-$(ACCOUNT_NAME)/global
	mkdir -p live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/{common,dev,stage,prod}
	cp templates/account-aws.hcl live/aws-$(ACCOUNT_NAME)/account.hcl
	cp templates/README.md live/aws-$(ACCOUNT_NAME)/README.md
	tee live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/region.hcl < templates/region.hcl >/dev/null
	tee live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/{common,dev,stage,prod}/environment.hcl < templates/environment.hcl >/dev/null

newgcp:
	echo 🧩 Bootstrapping the new Google Cloud account $(ACCOUNT_NAME)
	mkdir -p live/gcp-$(ACCOUNT_NAME)/global
	mkdir -p live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/{common,dev,stage,prod}
	cp templates/account-gcp.hcl live/gcp-$(ACCOUNT_NAME)/account.hcl
	cp templates/README.md live/gcp-$(ACCOUNT_NAME)/README.md
	tee live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/region.hcl < templates/region.hcl >/dev/null
	tee live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/{common,dev,stage,prod}/environment.hcl < templates/environment.hcl >/dev/null

build:
	@docker build --no-cache --pull -t iac .
clean:
	@docker system prune -f
plan:
	@docker run -it --rm \
		-v `pwd`:/code \
		-v $$HOME/.aws:/home/user/.aws \
		iac terragrunt run-all plan
shell:
	@docker run -it --rm -v `pwd`:/code iac sh


.PHONY: newaws newgcp
