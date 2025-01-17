NAME = Inception
MAKEFLAGS += -s

DOCKER_COMPOSE_FILE := ./srcs/docker-compose.yml
ENV := srcs/.env
DATA := $(HOME)/data
WORDPRESS_DATA := $(DATA)/wordpress
MARIADB_DATA := $(DATA)/mariadb

WORDPRESS_CONTAINER_NAME := wordpress
MARIADB_CONTAINER_NAME := mariadb

RESET   := \033[0m      
RED     := \033[0;31m
GREEN   := \033[0;32m
YELLOW  := \033[0;33m
BLUE    := \033[0;34m
MAGENTA := \033[0;35m
CYAN    := \033[0;36m
WHITE   := \033[0;37m  

all: check_running

build: create_dirs up_build

stop:
	@docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) stop

down:
	@read -p "Are you sure? Type 'yes' to proceed: " answer && \
	if [ "$$answer" != "yes" ]; then \
		echo "Aborted."; \
		false; \
	fi
	@printf "$(YELLOW)Stopping configuration $(NAME)...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) down

re: fclean create_dirs up_build

clean: down
	@printf "$(YELLOW)Cleaning remaining elements...$(NAME)...$(RESET)\n"
	@docker system prune -a --force

fclean: clean
	@printf "$(YELLOW)Removing all volumes...$(RESET)\n"
	@if [ -n "$$(docker volume ls -q)" ]; then \
		docker volume rm $$(docker volume ls -q); \
	else \
		printf "$(YELLOW)No volumes to remove.$(RESET)\n"; \
	fi
	@printf "$(YELLOW)Removing all data directories...$(RESET)\n"
	@sudo rm -fr $(DATA)
	@printf "$(GREEN)Full cleanup completed!$(RESET)\n"

logs:
	-@docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) logs -f

create_dirs:
	@if [ -d "$(DATA)" ]; then \
		printf "$(BLUE)Data directory $(DATA) already exists.$(RESET)\n"; \
	else \
		printf "$(YELLOW)Data directory $(DATA) does not exist. Creating it along with subdirectories...$(RESET)\n"; \
		sudo mkdir -p $(DATA) $(WORDPRESS_DATA) $(MARIADB_DATA); \
	fi

up:
	@printf "$(GREEN)Launching configuration $(NAME)...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) up -d

up_build:
	@printf "$(GREEN)Building and launching configuration $(NAME)...$(RESET)\n"
	@docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) up -d --build
	@echo "$$BANNER"

check_running:
	@container_status=$$(docker-compose -f $(DOCKER_COMPOSE_FILE) --env-file $(ENV) ps -q); \
	if [ "$$container_status" ]; then \
		printf "$(GREEN)Containers are already running. No need to relaunch.$(RESET)\n"; \
	else \
		printf "$(YELLOW)Containers are not running. Checking data directories...$(RESET)\n"; \
		if [ ! "$(ls -A $(WORDPRESS_DATA))" ] || [ ! "$(ls -A $(MARIADB_DATA))" ]; then \
			printf "$(BLUE)Data directories are empty. Triggering a rebuild...$(RESET)\n"; \
			$(MAKE) create_dirs; \
			$(MAKE) up_build; \
		else \
			printf "$(BLUE)Data directories are not empty. Launching existing configuration...$(RESET)\n"; \
			$(MAKE) up; \
		fi; \
	fi

.PHONY: all build down re clean fclean logs create_dirs up up_build check_running

define BANNER


.------..------..------..------..------..------..------..------..------.
|I.--. ||N.--. ||C.--. ||E.--. ||P.--. ||T.--. ||I.--. ||O.--. ||N.--. |
| (\/) || :(): || :/\: || (\/) || :/\: || :/\: || (\/) || :/\: || :(): |
| :\/: || ()() || :\/: || :\/: || (__) || (__) || :\/: || :\/: || ()() |
| '--'I|| '--'N|| '--'C|| '--'E|| '--'P|| '--'T|| '--'I|| '--'O|| '--'N|
`------'`------'`------'`------'`------'`------'`------'`------'`------'

endef
export BANNER
