# Utilities Stack

This stack groups small, standalone tools that do not belong to the media, dashboard, or edge stacks.

## Services

| Application                                       | Role                                                          | Port   |
| ------------------------------------------------- | ------------------------------------------------------------- | ------ |
| [BentoPDF](https://github.com/alam00000/bentopdf) | Privacy-first, client-side PDF editing and conversion toolkit | `3000` |

The `bentopdf-simple` image is the self-hosted build, which includes every PDF tool while hiding the public marketing pages.

## Setup

BentoPDF does not require any environment variables or first-run configuration.

Deploy the stack from this directory using the commands in the root README.

Open BentoPDF from the port in the services table.

### Reverse Proxy

To expose BentoPDF through the Edge stack, add a route to `edge/caddy/Caddyfile`:

```text
pdf.example.com {
    reverse_proxy bentopdf:8080
}
```

### Browser Requirements

BentoPDF processes files entirely in the browser, so files are never uploaded to the server.

Office document conversion uses LibreOffice WASM, which requires cross-origin isolation and a secure browser context.

`http://localhost` works for local testing, but access through a tailnet IP or another hostname usually needs HTTPS.

## Data and Maintenance

BentoPDF does not mount a persistent volume and does not store uploaded files.

There is no appdata directory to back up for this stack.

To update the container:

```shell
docker compose pull
docker compose up -d
```

## Security Notes

BentoPDF does not include built-in authentication.

Keep it on the tailnet or place it behind an authenticated reverse proxy before exposing it beyond the tailnet.
