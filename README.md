# Inception
## 📌 Overview

**Inception** is a **system administration project** from 42 School.
The goal is to virtualize a small infrastructure using **Docker Compose.**
Each service runs in its own container, built from a dedicated **Dockerfile.**
The project enforces good practices in **containerization, networking, and volume management.**

## Features
- Containers are built from scratch with Alpine Linux.
- No pre-built images are used (except Alpine base).
- Data persistence ensured via Docker volumes.
- HTTPS secured with SSL.
- Custom Makefile for automation.

## 🏗️ Project Architecture

This project sets up the following services:

- NGINX

    - Acts as a reverse proxy.

    - Handles HTTPS connections with a self-signed SSL certificate.

- WordPress + PHP-FPM

    - Runs WordPress with PHP-FPM (FastCGI Process Manager).

    - No Apache, as required by the subject.

- MariaDB

    - Database backend for WordPress.

    - Data persisted using Docker volumes.

- Docker Network

    - All containers are attached to a custom Docker network.

    - They communicate with each other without exposing internal ports.

- Volumes

    - WordPress files and MariaDB data are stored in volumes.

    - Ensures persistence across container restarts.

## ⚙️ Installation & Usage
1. **Fork and clone the repository**
```bash
git clone https://github.com/<your-username>/inception.git
cd inception
```
2. **Configure environment variables**

The project uses a `.env` file to store sensitive configuration.
Create your own .env inside **./srcs** directory
```bash
touch .env
``` 
Edit the file with your values:
```bash
DOMAIN_NAME=
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=
MYSQL_ROOT_PASSWORD=
WORDPRESS_TITLE=
WORDPRESS_ADMIN_USER=
WORDPRESS_ADMIN_PASSWORD=
WORDPRESS_ADMIN_EMAIL=
WORDPRESS_USER=
WORDPRESS_PASSWORD=
WORDPRESS_EMAIL=
```
3. **Add domain to `/etc/hosts`**

Map your domain name to **127.0.0.1:**
```bash
echo "127.0.0.1 <your_domain_name>" | sudo tee -a /etc/hosts
```
4. **Build and run the containers**
```bash
make build
```
5. **Access the services**
- WordPress: https://<your_domain_name>
- Admin Dashboard: https://<your_domain_name>/wp-admin

## 🛠️ Useful Makefile Commands

This project includes a `Makefile` to simplify building, running, and cleaning the Inception environment.

| Command                  | Description |
|---------------------------|-------------|
| `make` or `make all`      | Checks if containers are already running. If not, launches them. |
| `make build`              | Creates required directories and builds/starts the containers. |
| `make up`                 | Starts existing containers without rebuilding. |
| `make up_build`           | Builds and starts containers (forces rebuild). |
| `make stop`               | Stops running containers without removing them. |
| `make down`               | Stops and removes containers, networks, and volumes (asks for confirmation). |
| `make re`                 | Full rebuild: stops, cleans, recreates directories, builds, and runs containers. |
| `make clean`              | Stops containers, prunes Docker system (removes unused containers, networks, images). |
| `make fclean`             | Full cleanup: runs `clean`, removes all Docker volumes, and deletes the `$(HOME)/data` directory. ⚠️ **DANGER: Destroys all data** |
| `make logs`               | Follows logs of all containers. |
| `make create_dirs`        | Creates required data directories (`~/data/wordpress` and `~/data/mariadb`). |
| `make check_running`      | Checks if containers are running. If not, decides whether to rebuild or reuse existing data. |


## 🧩 Project Structure
```text
inception/
├── Makefile
├── docker-compose.yml
├── .env.example
├── srcs/
│   ├── requirements/
│   │   ├── mariadb/
│   │   │   └── Dockerfile
│   │   ├── nginx/
│   │   │   └── Dockerfile
│   │   └── wordpress/
│   │       └── Dockerfile
│   └── .env
└── volumes/
    ├── wordpress/
    └── mariadb/
```