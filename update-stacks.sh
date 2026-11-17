#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: ./update-stacks.sh [--dry-run]

Update every Compose stack in this repository.

Options:
  --dry-run  Show what would run without changing anything.
  -h, --help Show this help.
EOF
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

while (($# > 0)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
done

command -v docker >/dev/null 2>&1 || die "docker is not installed"
command -v flock >/dev/null 2>&1 || die "flock is not installed"
docker compose version >/dev/null 2>&1 || die "the docker compose plugin is not available"
docker info >/dev/null 2>&1 || die "cannot access the Docker daemon"

mapfile -d '' compose_files < <(
    find "$SCRIPT_DIR" \
        -mindepth 2 -maxdepth 2 \
        -type f \
        \( -name 'docker-compose.yml' -o -name 'docker-compose.yaml' -o -name 'compose.yml' -o -name 'compose.yaml' \) \
        -not -path '*/appdata/*' \
        -print0 |
        sort -z
)

((${#compose_files[@]} > 0)) || die "no compose files found in immediate subdirectories"

if ! $DRY_RUN; then
    lock_file="${XDG_RUNTIME_DIR:-/tmp}/homelab-update-stacks-${UID}.lock"
    exec 9>"$lock_file"
    flock -n 9 || die "another update is already running"
fi

declare -A seen_dirs=()
failed_stacks=()

for compose_file in "${compose_files[@]}"; do
    stack_dir="${compose_file%/*}"
    stack_name="${stack_dir##*/}"

    if [[ -n "${seen_dirs[$stack_dir]:-}" ]]; then
        continue
    fi
    seen_dirs["$stack_dir"]=1

    printf '\n==> %s\n' "$stack_name"

    if $DRY_RUN; then
        printf '    (cd %q && docker compose up -d --pull always --remove-orphans)\n' "$stack_dir"
        continue
    fi

    started_at=$SECONDS
    if (cd "$stack_dir" && docker compose up -d --pull always --remove-orphans); then
        printf '==> %s finished in %ss\n' "$stack_name" "$((SECONDS - started_at))"
    else
        printf '==> %s failed\n' "$stack_name" >&2
        failed_stacks+=("$stack_name")
    fi
done

if $DRY_RUN; then
    printf '\nDry run complete; no changes made.\n'
    exit 0
fi

if ((${#failed_stacks[@]} > 0)); then
    printf '\nFailed stacks: %s\n' "${failed_stacks[*]}" >&2
    exit 1
fi

printf '\nAll stacks updated successfully.\n'
