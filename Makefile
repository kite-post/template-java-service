# Той самий набір цілей, що й у решти репозиторіїв Kite: що в Java, що в Go,
# що у Vue — `make lint`, `make test`, `make image` роблять очікуване.

SERVICE ?= $(notdir $(CURDIR))
ORG     ?= kite-post
IMAGE   ?= ghcr.io/$(ORG)/$(SERVICE)
TAG     ?= dev
MVN     := $(if $(wildcard ./mvnw),./mvnw,mvn)

.DEFAULT_GOAL := help
.PHONY: help build lint fmt test test-it verify image run up down clean contracts rename

help: ## Показати цілі
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Зібрати jar без тестів
	$(MVN) -B -ntp clean package -DskipTests

lint: ## Перевірити формат і імпорти
	$(MVN) -B -ntp spotless:check

fmt: ## Відформатувати код
	$(MVN) -B -ntp spotless:apply

test: ## Юніт-тести
	$(MVN) -B -ntp test

test-it: ## Інтеграційні тести (*IT) разом з юніт-
	$(MVN) -B -ntp verify

verify: lint test-it ## Усе, що робить CI

image: ## Зібрати образ локально
	docker build -t $(IMAGE):$(TAG) .

run: ## Запустити локально з IDE-профілем
	$(MVN) -B -ntp spring-boot:run

up: image ## Підняти образ у контейнері на 8080
	docker run --rm -p 8080:8080 --memory 384m --name $(SERVICE) $(IMAGE):$(TAG)

down: ## Зупинити контейнер
	-docker rm -f $(SERVICE)

clean: ## Прибрати артефакти збірки
	$(MVN) -B -ntp clean

contracts: ## Згенерувати клієнтів і класи подій з kite-contracts
	@echo "kite-contracts ще не підключено до цього сервіса."
	@echo "Підключення: залежність ua.kite:kite-contracts, закріплена за тегом (5.4, п. 6),"
	@echo "далі розкоментуй ціль contracts-check нижче — CI почне її проганяти."

# contracts-check: ## Перевірити сумісність зі схемами kite-contracts
# 	$(MVN) -B -ntp kite-contracts:verify

rename: ## Перейменувати шаблон у справжній сервіс: make rename NAME=shipment-service
	@test -n "$(NAME)" || (echo "Вкажи ім'я: make rename NAME=shipment-service"; exit 1)
	@bash scripts/rename.sh "$(NAME)"
