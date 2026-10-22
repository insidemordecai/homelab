# Dashboard Stack

This stack provides a central dashboard for launching and monitoring the services in this homelab.

## Services

| Application                   | Role                                                                | Port   |
| ----------------------------- | ------------------------------------------------------------------- | ------ |
| [Homarr](https://homarr.dev/) | Customizable dashboard and service launcher with Docker integration | `7575` |

## Setup

Complete the shared setup in the root README first.

## Applications

### Homarr

Open Homarr from the port in the services table and complete the onboarding flow to configure the dashboard, users, and service integrations.

Generate an encryption key and add it to `.env`:

```shell
openssl rand -hex 32
```

```text
SECRET_ENCRYPTION_KEY=yourGeneratedKey
```

Review the remaining values in `docker-compose.yml` and adjust ports or volumes if needed.

The Docker socket is mounted at `/var/run/docker.sock` so Homarr can display container status and controls.
Remove that volume if you do not need Docker integration.

> [!WARNING]
> Access to the Docker socket effectively grants host-level control. Only run trusted dashboard images and do not expose this service publicly without authentication.

## Data and Maintenance

Application data is stored in each dashboard application's `appdata` directory, which is ignored by Git.
Back up the relevant directories before updating or reconfiguring an application.
