# Utilities Stack

This stack groups small, standalone tools that do not belong to the media, dashboard, or edge stacks.

## Services

| Application                                       | Role                                                          | Port   |
| ------------------------------------------------- | ------------------------------------------------------------- | ------ |
| [BentoPDF](https://github.com/alam00000/bentopdf) | Privacy-first, client-side PDF editing and conversion toolkit | `3000` |

## Setup

Complete the shared setup in the root README first.

## Applications

### BentoPDF

BentoPDF does not require any environment variables or first-run configuration.
Open BentoPDF from the port in the services table.

The `bentopdf-simple` image is the self-hosted build, which includes every PDF tool while hiding the public marketing pages.

BentoPDF processes files entirely in the browser, so files are never uploaded to the server.
Office document conversion uses LibreOffice WASM, which requires cross-origin isolation and a secure browser context.
`http://localhost` works for local testing, but access through a tailnet IP or another hostname usually needs HTTPS.

BentoPDF does not include built-in authentication, so keep it on the tailnet or place it behind an authenticated reverse proxy before exposing it.

## Data and Maintenance

BentoPDF does not mount a persistent volume and does not store uploaded files, so the utilities stack currently has no appdata directory to back up.
