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

## Stacks

### Edge

Public entry point and TLS termination. Cloudflare Tunnel exposes services
without opening inbound ports on the router, and Caddy reverse-proxies requests
to containers on `stacknet`.

| Application | Role | Port(s) |
| --- | --- | --- |
| [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (`cloudflared`) | Outbound-only tunnel to Cloudflare | — |
| [Caddy](https://caddyserver.com/) | Reverse proxy with automatic HTTPS via Cloudflare DNS | `80`, `443` |

Caddy routes are defined in [`edge/caddy/Caddyfile`](edge/caddy/Caddyfile) and
point at container names such as `jellyfin:8096`. See the
[Edge README](edge/README.md) for tunnel setup.

### Dashboard

| Application | Role | Port |
| --- | --- | --- |
| [Homarr](https://homarr.dev/) | Customizable dashboard and service launcher with Docker integration | `7575` |

The Docker socket is mounted so Homarr can show container status. Generate the
required encryption key with `openssl rand -hex 32` and add it to the `.env`.

### Media

Media servers, download clients, and automation. All applications share the
same data volume (`${DATA_VOLUME}/data:/data`) so downloads and libraries stay
consistent across containers.

| Application | Role | Port |
| --- | --- | --- |
| [qBittorrent](https://www.qbittorrent.org/) | Torrent download client | `8080` |
| [Prowlarr](https://prowlarr.com/) | Indexer manager for the Arr apps | `9696` |
| [Flaresolverr](https://github.com/FlareSolverr/FlareSolverr) | Cloudflare challenge bypass for indexers | `8191` |
| [Radarr](https://radarr.video/) | Movie collection manager | `7878` |
| [Sonarr](https://sonarr.tv/) | TV series collection manager | `8989` |
| [Trailarr](https://github.com/nandyalu/trailarr) | Downloads movie and show trailers | `7889` |
| [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr) | Cleans up stalled or unwanted downloads | `11011` |
| [Bazarr](https://www.bazarr.media/) | Subtitle management for Radarr and Sonarr | `6767` |
| [Jellyfin](https://jellyfin.org/) | Media server and streaming frontend | `8096` |
| [Seerr](https://github.com/seerr-team/seerr) | Media request portal for users | `5055` |
| [Audiobookshelf](https://www.audiobookshelf.org/) | Audiobook and podcast server | `13378` |

Jellyfin also exposes `8920` (HTTPS), `7359/udp` (client discovery), and
`1900/udp` (DLNA). qBittorrent exposes `6881` TCP/UDP for torrent traffic; that
port should be forwarded on the router to avoid being firewalled.

The media data layout is expected to look like this:

```text
data
├── torrents
│   ├── completed
│   └── incomplete
└── media
    ├── movies
    └── tv
```

Create it with:

```shell
mkdir -p torrents/{completed,incomplete} && mkdir -p media/{movies,tv}
```

Configuration and per-app setup steps are documented in the
[Media README](media/README.md).

### Utilities

| Application | Role | Port |
| --- | --- | --- |
| [BentoPDF](https://github.com/alam00000/bentopdf) | Browser-based PDF editing and conversion toolkit | `3000` |

### Accessing Services

By default, published ports are reachable at `http://localhost:<port>` on the
Docker host. When deployed behind the Edge stack, services are instead reached
through Caddy using hostnames you configure in `edge/caddy/Caddyfile`, for
example `https://media.example.com`.

## Security Notes

> [!CAUTION]
> `.env` files are ignored by Git, but be careful. Do NOT commit or push your
> local `.env` files, as they contain tokens, encryption keys, and other
> credentials.

- Keep real values out of `.env.example`; use obvious placeholders such as
  `pasteYourTokenHere`.
- Do not expose a service to the internet until it has authentication enabled.
- Only open firewall ports that you actually need. qBittorrent's listening port
  (`6881`) is a common exception; see the [Media README](media/README.md#firewall).
- Back up application configuration (`appdata/`) and media libraries before
  updating stateful services or changing volume mappings.

## Useful Links

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [LinuxServer.io images](https://docs.linuxserver.io/)
- [Cloudflare Tunnel documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Caddy documentation](https://caddyserver.com/docs/)
- [Jellyfin documentation](https://jellyfin.org/docs/)
- [Servarr Wiki](https://wiki.servarr.com/)
- [TRaSH Guides](https://trash-guides.info/)
- [Homarr documentation](https://homarr.dev/docs/)

