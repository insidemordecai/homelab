# Cloudflare Tunnel Setup 

## Setup Process
- Create a tunnel on [cloudflare.com](https://cloudflare.com) under *Zero Trust → Network → Tunnels*.
- After the setup online, copy the token given. This will typically be included in the command to install and run the connector. For example, for Docker, the command will look like what's shown below, copy what appears after `--token`.
```shell
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token randomTextHereAsTokenlSP1kY34p8^jKaX28XGo5xR5uVXftLHP0Y3+pBmT$jg
```
- Add this token in the `.env` as so, by replacing the value of the existing `TOKEN` variable:
```
TOKEN=randomTextHereAsTokenlSP1kY34p8^jKaX28XGo5xR5uVXftLHP0Y3+pBmT$jg
```
- Configure the application routes for the tunnel on the [cloudflare.com](https://cloudflare.com).
- Deploy the container 
