# Media Stack

This stack runs the media servers, download clients, and automation for the homelab.

## Table of Contents

- [Services](#services)
- [Setup](#setup)
    - [Environment](#environment)
    - [Folder Mapping](#folder-mapping)
- [Applications](#applications)
    - [qBittorrent](#qbittorrent)
    - [Prowlarr](#prowlarr)
    - [Flaresolverr](#flaresolverr)
    - [Radarr](#radarr)
    - [Sonarr](#sonarr)
    - [Bazarr](#bazarr)
    - [Jellyfin](#jellyfin)
    - [Seerr](#seerr)
    - [Trailarr](#trailarr)
    - [Cleanuparr](#cleanuparr)
    - [Audiobookshelf](#audiobookshelf)
- [Firewall](#firewall)

## Services

| Application                                                  | Role                                      | Port    |
| ------------------------------------------------------------ | ----------------------------------------- | ------- |
| [qBittorrent](https://www.qbittorrent.org/)                  | Torrent download client                   | `8080`  |
| [Prowlarr](https://prowlarr.com/)                            | Indexer manager for the Arr apps          | `9696`  |
| [Flaresolverr](https://github.com/FlareSolverr/FlareSolverr) | Cloudflare challenge bypass for indexers  | `8191`  |
| [Radarr](https://radarr.video/)                              | Movie collection manager                  | `7878`  |
| [Sonarr](https://sonarr.tv/)                                 | TV series collection manager              | `8989`  |
| [Bazarr](https://www.bazarr.media/)                          | Subtitle management for Radarr and Sonarr | `6767`  |
| [Jellyfin](https://jellyfin.org/)                            | Media server and streaming frontend       | `8096`  |
| [Seerr](https://github.com/seerr-team/seerr)                 | Media request portal for users            | `5055`  |
| [Trailarr](https://github.com/nandyalu/trailarr)             | Downloads movie and show trailers         | `7889`  |
| [Cleanuparr](https://github.com/Cleanuparr/Cleanuparr)       | Cleans up stalled or unwanted downloads   | `11011` |
| [Audiobookshelf](https://www.audiobookshelf.org/)            | Audiobook and podcast server              | `13378` |

## Setup

### Environment

Set the stack-specific values in `.env` before deploying.

| Variable      | Purpose                                                             |
| ------------- | ------------------------------------------------------------------- |
| `TZ`          | Timezone used by all containers, for example `Africa/Nairobi`       |
| `DATA_VOLUME` | Host directory that holds the `data` folder for media and downloads |

See the root README for the shared setup, network, and deployment steps.

### Folder Mapping

The stack expects media and torrents to live under `${DATA_VOLUME}/data`.
Create the directories before deploying:

```text
data
├── torrents
│   ├── completed
│   └── incomplete
└── media
    ├── movies
    ├── tv
    ├── audiobooks
    └── podcasts
```

```shell
mkdir -p torrents/{completed,incomplete} && mkdir -p media/{movies,tv,audiobooks,podcasts}
```

## Applications

### qBittorrent

Open qBittorrent from the port in the services table.
Log in with the username `admin` and the temporary password from the container logs:

```shell
docker logs qbittorrent
```

Change the credentials under *Web UI → Authentication*.

Recommended qBittorrent settings:

- *Web UI → Authentication*: bypass authentication for clients on localhost and change "Ban client after consecutive failures" to `0` if torrents stall, but use caution if the Web UI is exposed to the internet.
- *Downloads → Saving Management*: set the default save path to `/data/torrents/completed` and keep incomplete torrents in `/data/torrents/incomplete`.
- *Downloads → Saving Management*: switch to automatic torrent management.
- *Connections → Listening Port*: match the port forwarded on the router.
- *BitTorrent*: configure torrent queueing and seeding limits to your preference.

### Prowlarr

Open Prowlarr from the port in the services table.
Go to *Settings → Download Clients*, add qBittorrent with `qbittorrent` as the host and qBittorrent's credentials, then test and save.
Add the indexers you want under *Indexers*, test them, and save.

### Flaresolverr

Flaresolverr does not require any configuration itself.
In Prowlarr, go to *Settings → Indexers*, add Flaresolverr with the tag `flaresolverr` and `http://flaresolverr:8191/` as the host, then test and save.
Add the `flaresolverr` tag to any indexer that needs to bypass Cloudflare.

### Radarr

Open Radarr from the port in the services table.
Under *Settings → Media Management*, add `/data/media/movies` as a root folder.
Under *Settings → Download Clients*, add qBittorrent with `qbittorrent` as the host and qBittorrent's credentials.

Because Radarr and qBittorrent use the same `/data` mount, no remote path mapping is needed.

Copy the API key from *Settings → General*.
In Prowlarr, go to *Settings → Apps*, add Radarr, paste the API key, and use `http://radarr:7878` as the server address, then test and save.

Optional Radarr tweaks:

- *Media Management*: enable "Unmonitor Deleted Movies".
- *Media Management*: with advanced settings shown, set "Proper and Repacks" to "Do Not Prefer" so custom format scores drive selection.
- *Media Management*: follow the [Jellyfin movie naming scheme](https://jellyfin.org/docs/general/server/media/movies) for the movie folder format, including the IMDb external ID.
- *Custom Formats*: create formats for file size, x264, and x265 preferences.
- *Custom Formats*: import Repack/Proper from the [TRaSH Guides collection](https://trash-guides.info/Radarr/Radarr-collection-of-custom-formats/#repackproper).
- *Profiles*: uncheck Remux qualities if file size matters and score your custom formats so the preferred releases win.

### Sonarr

Open Sonarr from the port in the services table.
Under *Settings → Media Management*, add `/data/media/tv` as a root folder.
Under *Settings → Download Clients*, add qBittorrent with the same settings used in Radarr.

Because Sonarr and qBittorrent use the same `/data` mount, no remote path mapping is needed.

Copy the API key from *Settings → General*.
In Prowlarr, go to *Settings → Apps*, add Sonarr, paste the API key, and use `http://sonarr:8989` as the server address, then test and save.

Apply the Radarr tweaks where they apply and also enable "Rename Episodes" under *Media Management*.
Follow the [Jellyfin TV naming scheme](https://jellyfin.org/docs/general/server/media/shows) for the series folder format.

### Bazarr

Open Bazarr from the port in the services table.
Under *Settings → Sonarr*, enable the integration, fill in the Sonarr server details, test, and save.
Under *Settings → Radarr*, enable the integration, fill in the Radarr server details, test, and save.

Under *Settings → Languages*, choose a language filter, create a language profile, and set it as the default for movies and series.
Under *Settings → Providers*, add one or more subtitle providers and save.
Some providers require an account, while others such as Podnapisi, Supersubtitles, and TVSubtitles do not.

Under *Settings → Subtitles*, adjust embedded subtitle handling if your players have trouble with PGS or ASS subtitles.
Under *Audio Synchronization / Alignment*, enable automatic subtitle audio synchronization and set thresholds such as `96` for series and `86` for movies.

### Jellyfin

Open Jellyfin from the port in the services table.
Complete the first-run wizard and create an admin account.

Add libraries pointing at `/data/media/movies`, `/data/media/tv`, and `/data/media/audiobooks` or `/data/media/podcasts` as needed.
Optionally enable hardware transcoding if the host has a supported GPU.

### Seerr

Open Seerr from the port in the services table.
On first launch, choose Jellyfin as the media server, enter `http://jellyfin:8096` (hostname `jellyfin`, port `8096`), and sign in with a Jellyfin admin account.

Select the libraries Seerr should scan and start the scan.

Under *Settings → Services*, add Radarr and Sonarr with `http://radarr:7878` and `http://sonarr:8989`, their API keys, and the same root folders and quality profiles used in those apps.
Mark at least one Radarr server and one Sonarr server as the default.
Enable scan and automatic search for each server if you want requests to reach the Arr apps immediately.

Optionally import Jellyfin users under *Settings → Users* and configure request permissions and quotas.

Seerr is the successor to Jellyseerr, so older Jellyseerr guides generally apply, but use the current Seerr image and settings names.

### Trailarr

Open Trailarr from the port in the services table.
Log in with the default credentials `admin` / `trailarr` and change the password.

Go to *Settings → Connections*, add a Radarr connection, and use `http://radarr:7878` as the server URL with Radarr's API key.
Because Trailarr and Radarr share the same `/data` mount, use the same path for the path mapping.
Test the connection, validate the path mappings, and save.
Repeat the steps for Sonarr with `http://sonarr:8989`.

Choose a monitor type for each connection, for example `New` to only download trailers for newly added media.
Trailarr downloads trailers and stores them alongside the media files.

### Cleanuparr

Open Cleanuparr from the port in the services table.
On first launch, create an admin account.

Add Radarr and Sonarr with `http://radarr:7878` and `http://sonarr:8989`, their API keys, and the API version that matches each installed application.

Add qBittorrent as a download client with `http://qbittorrent:8080` and qBittorrent's credentials.
Leave the download path mapping empty because Cleanuparr and qBittorrent share the same `/data` mount.

Configure the Queue Cleaner to remove stalled or failed downloads, and enable the Malware Blocker with a blocklist.
Cleanuparr maintains blocklists at `https://cleanuparr.pages.dev/static/blacklist`, `https://cleanuparr.pages.dev/static/blacklist_permissive`, `https://cleanuparr.pages.dev/static/whitelist`, and `https://cleanuparr.pages.dev/static/whitelist_with_subtitles`.
Review the Download Cleaner rules before enabling them so seeding torrents are not removed too early.

### Audiobookshelf

Open Audiobookshelf from the port in the services table.
There are no default credentials, so create the first admin account.

Add a Books library pointing at `/data/media/audiobooks` and a Podcasts library pointing at `/data/media/podcasts`.
Create those folders under `${DATA_VOLUME}/data/media` first if they do not exist.
Choose a metadata provider and let the initial scan complete.

The mobile apps can connect using the host's tailnet address and the Audiobookshelf port.

## Firewall

Allow only the ports you actually need through the host firewall.
qBittorrent's listening port (`6881` TCP/UDP) usually needs to be allowed and forwarded on the router so torrents are not throttled.

If you use `ufw`:

```shell
sudo ufw allow 6881/tcp
sudo ufw allow 6881/udp
```

Expose media services through the Edge stack and Cloudflare Tunnel rather than opening their ports directly, and only expose services that have authentication enabled.
