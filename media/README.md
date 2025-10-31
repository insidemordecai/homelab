# Media Server and Aggregation
This setup is based on Docker to install media servers and aggregators for easy sourcing of files and streaming. 
## Table of Contents
- [Prerequisite](#prerequisite)
- [Setup Process](#setup-process)
  - [Folder Mapping](#folder-mapping)
  - [Step 0](#step-0)
  - [qBittorrent](#qbittorrent)
  - [Arr Apps](#arr-apps)
    - [Prowlarr](#prowlarr)
    - [Flaresolverr](#flaresolverr)
    - [Radarr](#radarr)
    - [Sonarr](#sonarr)
    - [Bazarr](#bazarr)
  - [Jellyfin](#jellyfin)
  - [Jellyseerr](#jellyseerr)
- [Firewall](#firewall)
- [Useful Links](#useful-links)
## Prerequisite 
You need to have these installed: 
- [Docker](https://docs.docker.com/engine/install/) 
- [Docker Compose](https://docs.docker.com/compose/install/)
## Setup Process
### Folder Mapping 
At a high level, all the files will be under `/data` on our hard drive. 
This is my current setup:
```
data
├── torrents
│   ├── completed
│   └── incomplete
└── media
    ├── movies
    └── tv
```

Create your directories before proceeding. 
Here's an easy command to run in your `/data` directory if you want a similar directory scheme.
```shell
mkdir -p torrents/{completed,incomplete} && mkdir -p media/{movies,tv}
```
### Step 0
- Clone this repository or download a zip of it.
- In the root directory, run this command to copy all `.env.example` templates as `.env` in each subdirectory for you to edit.
```shell
find . -name '.env.example' -execdir cp .env.example .env \;
```
- Navigate to the directory with the `docker-compose.yml` file. 
- Add your user to the `docker` group to not have to prepend `sudo` to each docker command.
```shell
sudo usermod -aG docker $USER
newgrp docker # reload group permissions immediately
```
- Change ownership of the data volume specified in the `.env` file to allow all services to have access to directories mapped to them. 
```shell
chown -R 1000:1000 /data/volume/in/.env/file
```
- Create the `stacknet` network. 
```shell
docker network create stacknet
```
- Edit the `.env` files and use the following commands with Docker. 
```shell
docker compose up -d # to deploy containers
docker compose stop # to stop containers 
docker compose rm # to remove containers (stop container first)
```
- Configure the different apps now.

> [!CAUTION]
> `.env` files are ignored but be careful.
> Do NOT commit or push the changes you make to the `.env` files to avoid sharing your tokens.
### qBittorrent
http://localhost:8080

Launch qBittorrent and enter its credentials. 
The username is `admin` while the password is randomly generated on launch.
To find this password you can view the logs: 
```shell
docker logs qbittorrent
```
Now, head into settings and change the credentials under *Web UI → Authentication*.

Configure qBittorrent to you liking, I personally prefer to: 
- *Web UI → Authentication*
	- Bypass authentication for clients on localhost 
	- Change 'Ban client after consecutive failures' to 0 - at some point it used to stall out torrents but exercise caution with this especially if the download client is exposed to the internet 
- *Downloads → Saving Management*
	- Default save path: `/data/torrents/completed` 
	- Keep incomplete torrents in: `/data/torrents/incomplete`
	- Switch to Automatic torrent management 
- *Connections → Listening Port*
	- Match the port with what you have forwarded from your router.
- *BitTorrent*
	- Configure Torrent Queueing to your preference.
	- Set up Seeding Limits

### Arr Apps
#### Prowlarr 
http://localhost:9696

Head to *Settings → Download Clients*, click on the `+` symbol and add qBittorrent.

Match the port with what is set on qBittorrent's Web UI (default is 8080) and add in qBittorrent's username and password. 

For 'Host', you can have it as `qbittorrent` if 

Test and save.

Now add the indexers you want, test and save.
#### Flaresolverr
Flaresolverr doesn't require any configuration itself. 

Go to Prowlarr and head to *Settings → Indexers*, click on the `+` symbol and add Flaresolverr. 
Give it a name, have the tag as `flaresolverr` and host should be `http://flaresolverr:8191/`.
Test and save. 

Now any problematic indexer in Prowlarr should bypass Cloudflare, simply search for the indexer and add the tag `flaresolverr` to it.

#### Radarr 
http://localhost:7878

Head to *Settings → Media Management*, add Root Folder and set it `/data/media/movies`. 
Should be under `/data` in line with the `docker-compose.yml`, match what is on the right side of the volume configuration. 

Go to *Settings → Download Clients*, click on the `+` symbol and add qBittorrent (similar steps to Prowlarr above), test and save. 

Still under *Download Clients*, configure Remote Path Mapping.
Leave host as `localhost` and set your remote path according to your `docker-compose.yml`.
In this case our volume is `${DATA_VOLUME}/data:/data` so we will map it like this:
- Remote path: `/WHERE_YOUR_DATA_VOLUME_IS/data/torrents/completed` 
- Local path: `/data/torrents/completed`

Go to *Settings→ General*, scroll down to API key and copy it.
Go to Prowlarr then *Settings → Apps*, click on the `+` , add Radarr  and paste the API key.
Change the Prowlarr and Radarr server address to match this format: `http://container-name:port`.
Test and save. 

That's the main steps, now you can tweak Radarr to your liking. 
I personally like to:
- *Media Management*:
	- Check 'Unmonitor Delete Movies' 
	- Show Advanced and change 'Proper and Repacks' to 'Do Not Prefer', this will use our custom formats scoring to pick the preferred media.
	- Show Advanced and change 'Movie Folder Format'. I typically add IMDb external ID inline with [Jellyfin Movies naming scheme](https://jellyfin.org/docs/general/server/media/movies).
- Add a few custom formats under *Custom Formats* 
	- Medium File Size - set you minimum and max file size for media downloaded and check 'Required'. You can create another for Small and Large file sizes if you desire.
	- x264 - use preset under 'Release Title' and check 'Required' to find files encoded with H.264.
	- x265 - use preset under 'Release Title' and check 'Required' to find files encoded with H.265. 
	- Repack/Proper - import from [TRaSH Guide's Collection](https://trash-guides.info/Radarr/Radarr-collection-of-custom-formats/#repackproper) to allow Radarr to still pick repacks/proper files. 
- Tweak different quality profiles under *Profiles*
	- Uncheck Remux since they tend to be large files.
	- Set the score for the custom formats created e.g 1000 for Medium File Size, and 1 for Repack/Proper. You can also score x264 and x265 depending on your preference. and your media player's codec support.
#### Sonarr
http://localhost:8989

Sonarr setup is very similar to Radarr so this should be straightforward. 

Head to *Settings → Media Management*, add Root Folder and set it `/data/media/tv`. 

Go to *Settings → Download Clients*, click on the `+` symbol, add qBittorrent and repeat the same steps as Radarr above. 

Still under *Download Clients*, configure Remote Path Mapping.
- Leave host as `localhost`
- Remote path: `/WHERE_YOUR_DATA_VOLUME_IS/data/torrents/completed` 
- Local path: `/data/torrents/completed`

Go to *Settings→ General*, scroll down to API key and copy it.
Go to Prowlarr then *Settings → Apps*, click on the `+` , add Sonarr  and paste the API key.
Change the Prowlarr and Sonarr server address to match this format: `http://container-name:port`.
Test and save.

For tweaks to Sonarr settings, look at Radarr's tweaks as they are similar.
One major difference to account for is:
- *Media Management*
	- Follow [Jellyfin TV Shows naming scheme](https://jellyfin.org/docs/general/server/media/shows) to add IMDb external ID to the 'Series Folder Format'.
 	- Check 'Rename Episodes'.
#### Bazarr
http://localhost:6767

Head into *Settings → Sonarr* and enable it. 
Fill in your Sonarr server details and test. 
Set the minimum score in *Options* (TRaSH-Guide recommend `90`) and save your settings. 

Repeat the same steps for Radarr by heading into *Settings → Radarr* and enable it. 
Fill in your Radarr server details and test.
Set the minimum score to `80` and save your settings.

Now go to *Settings → Languages*. 
Pick your desired language in the 'Language Filter'. 
Under *Language Profiles*, select 'Add New Profile' and give it a name.
Click on `Add` to add the language(s) you enabled earlier and configure the other options.
Under *Default Language Profiles For Newly Added Shows*, enable 'Series' and 'Movies' and pick the profile you created.
Save your settings. 

Go to *Settings → Providers* and click on the `+` symbol to add your subtitle provider. 
You will be required to enter you credentials for these providers such as [opensubtitles.com](https://opensubtitles.com), therefore, create an account with your desired provider first.
Some that will not require you to create an account include: Podnapisi, Supersubtitles and TVSubtitles.
Save your settings. 

Under *Settings → Subtitles*, scroll to *Embedded Subtitles Handling*. 
You might prefer to enable 'Ignore Embedded PGS Subtitles' and 'Ignore Embedded ASS Subtitles' if your media players have issues with these type of subtitles. 
For example, Jellyfin for Samsung TV (check out [Jellyfin 2 Samsung](https://github.com/PatrickSt1991/Samsung-Jellyfin-Installer) and [Install Jellyfin Tizen](https://github.com/Georift/install-jellyfin-tizen) for how to sideload the app) attempts to transcode when selecting PGS subtitles but just never plays. 
Scroll to *Audio Synchronization / Alignment* and enable 'Automatic Subtitles Audio Synchronization'. 
Set the 'Score Threshold For Audio Sync' as `96` for Series and `86` for Movies. 
Save your settings
That's it, you can follow the tweaks made in Radarr in Sonarr as well. 
### Jellyfin
http://localhost:8096 

Configure Jellyfin on your browser and add your media library with matching folders as what is in the `docker-compose.yml` file. 
That is `/data/media/movies` and `data/media/tv` in our case
### Jellyseerr 
http://localhost:5055

Open Jellyseerr and follow the on-screen guide.
- Enter the Jellyfin hostname `jellyfin` and leave the port as is unless you had changed this. 
- Test and save. API keys will be configured automatically.
- Add Radarr and Sonarr. 
## Firewall
You might need to allow certain ports through your firewall but exercise caution.
It is better to not manually allow anything through until you come across a situation where you need to.

For example, you might need to allow the port qBittorrent is listening on to prevent your torrents from being firewalled and thus throttled. 
If you have `ufw` you can allow with this command. 
```shell 
sudo ufw allow 6881/tcp # default listening port on qBittorrent
sudo ufw allow 6881/udp
```

Perhaps you might want to expose Jellyfin, you can run this command. 
```shell
sudo ufw allow 8096
```
## Useful Links
- [Servarr Wiki](https://wiki.servarr.com/)
- [TRaSH Guides](https://trash-guides.info/)
- [TechHut's Setup](https://github.com/TechHutTV/homelab/)
