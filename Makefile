VENDOR=JetRails
MODULE=Cloudflare
NAMESPACE=$(VENDOR)"_"$(MODULE)
NAMESPACE_PATH=$(VENDOR)"/"$(MODULE)
VERSION=$(shell git describe --tags `git rev-list --tags --max-count=1`)
MODULE_FILES=Block Console Controller Helper Model etc view registration.php
MODULE_FILES_EXTRA=composer.json LICENSE.md

.PHONY: deps build bump deploy watch package clean nuke dev-create dev-up dev-down dev-nuke

deps: ## Download dependencies
	yarn install

build: ## Build styles and scripts
	yarn build

bump: ## Bump version in source files based on latest git tag
	VERSION=$(VERSION); find Block Console Controller Helper Model etc view -type f -iname "*.php" -exec sed -E -i '' "s/([\t ]+\*[\t ]+@version[\t ]+)(.*)/\1$$VERSION/g" {} +
	VERSION=$(VERSION); sed -E -i '' "s/(Version-)(.+)(-orange)/\1$$VERSION\3/g" ./README.md
	VERSION=$(VERSION); sed -E -i '' "s/(\"version\": \")(.+)(\")/\1$$VERSION\3/g" ./composer.json

deploy: ## Deploy code to public_html directory
	NAMESPACE_PATH=$(NAMESPACE_PATH); mkdir -p "./public_html/app/code/$$NAMESPACE_PATH"
	NAMESPACE_PATH=$(NAMESPACE_PATH); rsync -uavq $(MODULE_FILES) "./public_html/app/code/$$NAMESPACE_PATH"

watch: deploy ## Intermittently sync code to public_html directory
	fswatch -o $(MODULE_FILES) | xargs -n1 -I{} make deploy

package: bump build ## Package into archive file
	rm -rf ./dist
	mkdir -p ./dist
	VERSION=$(VERSION); NAMESPACE=$(NAMESPACE); zip -r dist/$$NAMESPACE-$$VERSION.zip $(MODULE_FILES) $(MODULE_FILES_EXTRA)

clean: ## Remove generated files and folders
	rm -rf ./dist ./.parcel-cache

nuke: clean ## Remove generated & deployment data
	rm -rf ./node_modules ./public_html

dev-create: ## Create development environment
	composer global config repositories.magento composer https://repo.magento.com/
	composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.2 ./public_html
	cp .magento.docker.yml .magento.setup.params ./public_html
	cd public_html && composer require magento/ece-tools -w
	cd public_html && ./vendor/bin/ece-docker build:compose --with-test --with-selenium --no-varnish --mode developer
	cd public_html && docker-compose up -d
	cd public_html && docker-compose run --rm deploy bin/magento setup:install `cat .magento.setup.params | tr '\n' ' '` ;
	cd public_html && docker-compose run --rm deploy magento-command deploy:mode:set developer
	cd public_html && docker-compose run --rm deploy magento-command module:disable Magento_TwoFactorAuth
	cd public_html && docker-compose run --rm deploy magento-command cache:flush

dev-up: ## Spin development environment up
	docker-compose -f ./public_html/docker-compose.yml up -d

dev-down: ## Spin development environment down
	docker-compose -f ./public_html/docker-compose.yml down

dev-nuke: dev-down nuke ## Spin development environment down
	docker volume rm public_html_magento-development-magento-db

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
