default: help

hugo: ## Build the blog to /public
	npm install postcss-cli
	hugo --minify

dev: ## Run local server in watch mode
	hugo serve -w

help: ## Prints help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
