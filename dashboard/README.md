# Dashboard Stack

This stack provides a central dashboard for launching and monitoring the services in this homelab.

| Application                   | Role                                                                | Port   |
| ----------------------------- | ------------------------------------------------------------------- | ------ |
| [Homarr](https://homarr.dev/) | Customizable dashboard and service launcher with Docker integration | `7575` |

## Setup

### Configuration

Generate an encryption key and add it to `.env`:

```shell
openssl rand -hex 32
```

```text
SECRET_ENCRYPTION_KEY=yourGeneratedKey
```

Review the remaining values in `docker-compose.yml` and adjust ports or volumes if needed.

### Docker Integration

The Docker socket is mounted at `/var/run/docker.sock` so the dashboard can display container status and controls.
Remove that volume if you do not need Docker integration.

> [!WARNING]
> Access to the Docker socket effectively grants host-level control. Only run trusted dashboard images and do not expose this service publicly without authentication.

### Deploy

```shell
docker compose up -d
```

Open `http://localhost:7575` and complete the onboarding flow to configure the dashboard, users, and service integrations.

### Reverse Proxy

To expose the dashboard through the Edge stack, add a route to `edge/caddy/Caddyfile`:

```text
dash.example.com {
    reverse_proxy homarr:7575
}
```

## Data and Maintenance

Application data is stored in `./appdata/homarr`, which is ignored by Git.
Back up that directory before updating the container or changing its configuration.

To update the stack:

```shell
docker compose pull
docker compose up -d
```
