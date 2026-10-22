# My Homelab Setup

Docker Compose stacks and notes for running my self-hosted services.

Each stack lives in its own directory, ships with a `.env.example` template, and
joins the shared external `stacknet` network so containers can reach each other
by name.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
  - [Clone the Repository](#clone-the-repository)
  - [Create the .env Files](#create-the-env-files)
  - [Docker Permissions](#docker-permissions)
  - [Data Ownership](#data-ownership)
  - [Create the Shared Network](#create-the-shared-network)
  - [Deploy a Stack](#deploy-a-stack)
- [Stacks](#stacks)
  - [Edge](#edge)
  - [Dashboard](#dashboard)
  - [Media](#media)
  - [Utilities](#utilities)
- [Security Notes](#security-notes)
- [Useful Links](#useful-links)

## Repository Structure

```text
homelab
├── dashboard/          # Homarr dashboard
├── edge/               # Cloudflare Tunnel + Caddy reverse proxy
├── media/              # Media servers, downloaders, and automation
├── utilities/          # Small standalone tools
└── README.md
```

Every stack follows the same basic shape:

```text
<stack>
├── docker-compose.yml
├── .env.example
└── README.md           # Stack-specific setup notes (where available)
```

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/) (the `docker compose` plugin)
- A host directory for persistent data, mounted into containers as configured in each `.env`

## Setup

### Clone the Repository

```shell
git clone https://github.com/insidemordecai/homelab.git
cd homelab
```

### Create the .env Files

Each stack reads its configuration from a local `.env` file. Copy every
`.env.example` template in the repository to `.env` in the same directory with:

```shell
find . -name '.env.example' -execdir cp .env.example .env \;
```

Then edit each `.env` and fill in the values for your environment. The `.env`
files are ignored by Git, so your local values will not be committed.

### Docker Permissions

Add your user to the `docker` group so you do not need to prepend `sudo` to
every Docker command:

```shell
sudo usermod -aG docker $USER
newgrp docker # reload group permissions immediately
```

### Data Ownership

Change ownership of the data volume referenced in the `.env` files so the
containers (which typically run as UID/GID `1000`) can read and write it:

```shell
chown -R 1000:1000 /path/to/your/data/volume
```

### Create the Shared Network

All stacks use the same external network, so create it once:

```shell
docker network create stacknet
```

### Deploy a Stack

From the directory containing the `docker-compose.yml` file:

```shell
docker compose up -d    # deploy containers
docker compose stop     # stop containers
docker compose rm       # remove containers (stop them first)
```

