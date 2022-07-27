.SILENT: # do not echo commands as we run them
.DEFAULT_GOAL := help

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
# if the first argument is "newmod"
else ifeq (newmod,$(firstword $(MAKECMDGOALS)))
    # use the rest as arguments for "newmod"
    MODULE_NAME := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    # fail if MODULE_NAME is not defined
    ifndef MODULE_NAME
        $(error ❌ MODULE_NAME is not set)
    endif
    # and turn them into do-nothing targets
    $(eval $(MODULE_NAME):;@:)
endif

newaws: ## bootstrap new AWS account
	echo 🧩 Bootstrapping the new AWS account $(ACCOUNT_NAME)
    # creating the base directory structure
	mkdir -p live/aws-$(ACCOUNT_NAME)/global
	mkdir -p live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/{common,dev,stage,prod}
    # copying files into account directory
	cp templates/aws/account.hcl live/aws-$(ACCOUNT_NAME)/account.hcl
	cp templates/aws/README-account.md live/aws-$(ACCOUNT_NAME)/README.md
	cp templates/aws/README-global.md live/aws-$(ACCOUNT_NAME)/global/README.md
	tee live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/README.md < templates/aws/README-region.md >/dev/null
	tee live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/region.hcl < templates/aws/region.hcl >/dev/null
	tee live/aws-$(ACCOUNT_NAME)/{us-east-1,us-west-2}/{common,dev,stage,prod}/environment.hcl < templates/aws/environment.hcl >/dev/null
    # put correct region and environment into configuration files
	for region in us-east-1 us-west-2; do \
		sed -ibak "s/awsdefault/$${region}/g" "live/aws-$(ACCOUNT_NAME)/$${region}/region.hcl"; \
		sed -ibak "s/gcpdefault//g" "live/aws-$(ACCOUNT_NAME)/$${region}/region.hcl"; \
		rm "live/aws-$(ACCOUNT_NAME)/$${region}/region.hclbak"; \
		for env in dev stage prod; do \
			sed -ibak "s/N\/A/$${env}/g" "live/aws-$(ACCOUNT_NAME)/$${region}/$${env}/environment.hcl"; \
			rm "live/aws-$(ACCOUNT_NAME)/$${region}/$${env}/environment.hclbak"; \
		done \
	done
    # replacing account-level variables
	sed -ibak "s/awsdefault/$(ACCOUNT_NAME)/g" live/aws-$(ACCOUNT_NAME)/account.hcl
	sed -ibak "s/gcpdefault//g" live/aws-$(ACCOUNT_NAME)/account.hcl
	rm live/aws-$(ACCOUNT_NAME)/account.hclbak

newgcp: ## bootstrap new GCP account
	echo 🧩 Bootstrapping the new Google Cloud account $(ACCOUNT_NAME)
    # creating the base directory structure
	mkdir -p live/gcp-$(ACCOUNT_NAME)/global
	mkdir -p live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/{common,dev,stage,prod}
    # copying files into account directory
	cp templates/gcp/account.hcl live/gcp-$(ACCOUNT_NAME)/account.hcl
	cp templates/gcp/README-account.md live/gcp-$(ACCOUNT_NAME)/README.md
	cp templates/gcp/README-global.md live/gcp-$(ACCOUNT_NAME)/global/README.md
	tee live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/README.md < templates/gcp/README-region.md >/dev/null
	tee live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/region.hcl < templates/gcp/region.hcl >/dev/null
	tee live/gcp-$(ACCOUNT_NAME)/{us-east2,us-west1}/{common,dev,stage,prod}/environment.hcl < templates/gcp/environment.hcl >/dev/null
    # put correct region and environment into configuration files
	for region in us-east2 us-west1; do \
		sed -ibak "s/gcpdefault/$${region}/g" "live/gcp-$(ACCOUNT_NAME)/$${region}/region.hcl"; \
		sed -ibak "s/awsdefault//g" "live/gcp-$(ACCOUNT_NAME)/$${region}/region.hcl"; \
		rm "live/gcp-$(ACCOUNT_NAME)/$${region}/region.hclbak"; \
		for env in dev stage prod; do \
			sed -ibak "s/N\/A/$${env}/g" "live/gcp-$(ACCOUNT_NAME)/$${region}/$${env}/environment.hcl"; \
			rm "live/gcp-$(ACCOUNT_NAME)/$${region}/$${env}/environment.hclbak"; \
		done \
	done
	sed -ibak "s/gcpdefault/$(ACCOUNT_NAME)/g" live/gcp-$(ACCOUNT_NAME)/account.hcl
	sed -ibak "s/awsdefault//g" live/gcp-$(ACCOUNT_NAME)/account.hcl
	rm live/gcp-$(ACCOUNT_NAME)/account.hclbak

newmod: ## bootstrap new module
	echo 🧩 Bootstrapping the new infrastructure module $(MODULE_NAME)
	mkdir -p modules/$(MODULE_NAME)
	touch modules/$(MODULE_NAME)/{main,variables,outputs}.tf
	echo "# $(MODULE_NAME) module" > modules/$(MODULE_NAME)/README.md

build: ## build toolbox container
	docker build --no-cache --pull -t iactools .

clean: ## clean docker stuff
	docker system prune -f

plan: ## run terraform plan
	docker run -it --rm \
		-v `pwd`:/code \
		-v $$HOME/.aws:/home/user/.aws \
		iactools terragrunt run-all plan

shell: ## start container shell
	docker run -it --rm -v `pwd`:/code iactools sh

check: ## run pre-commit linter
	pre-commit run -a || echo "pre-commit missing"

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: newaws newgcp newmod
