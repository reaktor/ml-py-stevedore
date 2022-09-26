DC=docker
UNAME_S := $(shell uname -s)
NAME=ml-py-stevedore

## Google cloud deployment values
PROJECT=
REGION=
ORGANIZATION=
BILLING=


.PHONY: help

help: ## *:･ﾟ✧*:･ﾟ✧ This help *:･ﾟ✧*:･ﾟ✧
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m[ \033[36m%-16s \033[33m]\033[0m  %s\n", $$1, $$2}'

-: ## === Local Development ===

local-run: local-stop local-build ## Start Docker service
	$(DC) run -d -p 8000:8000 --rm --name $(NAME) $(NAME)
	$(DC) logs -f $(NAME)

local-run-alternative: local-stop local-build ## Start Docker service with alternative model
	$(DC) run -d -p 8000:8000 --rm --name $(NAME) -v $$(pwd)/alternative_model:/service/model $(NAME)
	$(DC) logs -f $(NAME)

local-build: ## Build container for running
	$(DC) build -t $(NAME) .

local-shell: ## Run shell in container for debugging
	$(DC) run --rm -ti $(NAME) bash -l

local-stop: ## Stop all services
	$(DC) stop -t 0 $(NAME) || true

local-test-curl: ## Test service with curl
	curl -f -s -D /dev/stderr http://localhost:8000/health/live || echo Failed; echo
	curl -f -s -D /dev/stderr http://localhost:8000/readyz || echo Failed; echo
	curl -f -s -D /dev/stderr -X GET http://localhost:8000/health/ready/?model=test_logreg1 || echo Failed; echo
	curl -f -s -D /dev/stderr -X GET http://localhost:8000/version/?model=test_logreg1 || echo Failed; echo
	curl -f -s -D /dev/stderr http://localhost:8000/docs >/dev/null || echo Failed; echo
	curl -f -s -D /dev/stderr http://localhost:8000/health/uptime || echo Failed; echo
	curl -f -s -D /dev/stderr -X 'POST' \
	  'http://localhost:8000/predict/' \
	  -H 'accept: application/json' \
	  -H 'Content-Type: application/json' \
	  -d '{ "predictor": "test_logreg1", "payload": [[1,2,3]]}' || echo Failed; echo



local-test-curl-alternative: ## Test service with curl when using alternative model
	curl -f -s -D /dev/stderr http://localhost:8000/health/live || echo Failed; echo;
	curl -f -s -D /dev/stderr http://localhost:8000/readyz || echo Failed; echo;
	curl -f -s -D /dev/stderr -X GET http://localhost:8000/health/ready/?model=test_logreg3 || echo Failed; echo;
	curl -f -s -D /dev/stderr -X GET http://localhost:8000/version/?model=test_logreg3 || echo Failed; echo;
	curl -f -s -D /dev/stderr http://localhost:8000/docs >/dev/null || echo Failed; echo;
	curl -f -s -D /dev/stderr http://localhost:8000/health/uptime || echo Failed; echo;
	curl -f -s -D /dev/stderr -X 'POST' \
		  'http://localhost:8000/predict/' \
		  -H 'accept: application/json' \
		  -H 'Content-Type: application/json' \
		  -d '{ "predictor": "test_logreg3", "payload": [[0,0,0],[10,10,10]]}' || echo Failed; echo

local-pytest: local-build ## Run testcases in container
	$(DC) run --rm --name $(NAME)-test \
		--entrypoint /service/pytest.sh \
		$(NAME)

local-pytest-alternative: local-build ## Run testcases in container
	$(DC) run --rm --name $(NAME)-test -v $$(pwd)/alternative_model:/service/model \
		--entrypoint /service/pytest.sh \
		$(NAME)

-: ## === Cloud Deploy ===

## Google

g-create-project: ## Create project
	gcloud projects create $(PROJECT) --enable-cloud-apis --organization=$(ORGANIZATION)
	gcloud alpha billing projects link $(PROJECT) --billing-account=$(BILLING)
	gcloud --project=$(PROJECT) services enable cloudbuild.googleapis.com

g-build-image: ## Submit to google cloud
	gcloud --project=$(PROJECT) builds submit --tag gcr.io/$(PROJECT)/$(NAME):latest --timeout=2h

g-deploy-service: ## Submit to google cloud
	gcloud --project=$(PROJECT) run deploy $(NAME) --image=gcr.io/$(PROJECT)/$(NAME):latest --region=$(REGION) --port=8000

g-test-service: ## send test file
	bash -x -e -c "\
		URL=$$( gcloud --project=$(PROJECT) run services describe $(NAME) --region=$(REGION) --format=json | jq .status.url ); \
		curl -f -s -D /dev/stderr \$$URL/health/live ; echo; \
		curl -f -s -D /dev/stderr \$$URL/readyz; echo; \
		curl -f -s -D /dev/stderr -X GET \$$URL/health/ready/?model=test_logreg1; echo; \
		curl -f -s -D /dev/stderr -X GET \$$URL/version/?model=test_logreg1 ; echo; \
	"

g-delete-service: ## Stop service
	gcloud --project=$(PROJECT) run services delete $(NAME) --region=$(REGION)

g-delete-image: ## Stop service
	gcloud --project=$(PROJECT) container images delete gcr.io/$(PROJECT)/$(NAME) --force-delete-tags

g-delete-project: ## Delete project
	gcloud projects delete $(PROJECT)

