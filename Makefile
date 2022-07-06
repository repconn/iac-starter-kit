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
