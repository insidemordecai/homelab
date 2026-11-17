#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=false

# Enable colour only for interactive terminals and when the environment allows it.
if [[ -t 1 && -t 2 && -z ${NO_COLOR:-} && ${TERM:-dumb} != "dumb" ]]; then
    BOLD=$'\033[1m'
    BLUE=$'\033[34m'
    GREEN=$'\033[32m'
    RED=$'\033[31m'
    YELLOW=$'\033[33m'
    RESET=$'\033[0m'
else
    BOLD='' BLUE='' GREEN='' RED='' YELLOW='' RESET=''
fi

# Print command-line help.
usage() {
    cat <<'EOF'
Usage: ./update-stacks.sh [--dry-run]

Update every Compose stack in this repository.

Options:
  --dry-run  Show what would run without changing anything.
  -h, --help Show this help.
EOF
}

# Print an error to stderr and exit with a failure status.
die() {
    printf '%serror:%s %s\n' "$RED" "$RESET" "$*" >&2
    exit 1
}

# Parse the supported command-line options.
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

# Fail early with a clear message if the environment is not ready.
command -v docker >/dev/null 2>&1 || die "docker is not installed"
command -v flock >/dev/null 2>&1 || die "flock is not installed"
docker compose version >/dev/null 2>&1 || die "the docker compose plugin is not available"
docker info >/dev/null 2>&1 || die "cannot access the Docker daemon"

# Stack directories are top-level, so search one level below the repo root.
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

# Prevent overlapping updates; dry runs are read-only and can run together.
if ! $DRY_RUN; then
    lock_file="${XDG_RUNTIME_DIR:-/tmp}/homelab-update-stacks-${UID}.lock"
    exec 9>"$lock_file"
    flock -n 9 || die "another update is already running"
fi

# Track directories already processed and any stacks that failed.
declare -A seen_dirs=()
failed_stacks=()

# Update each discovered stack from its own directory.
for compose_file in "${compose_files[@]}"; do
    stack_dir="${compose_file%/*}"
    stack_name="${stack_dir##*/}"

    # Only process a directory once if it contains multiple compose filenames.
    if [[ -n "${seen_dirs[$stack_dir]:-}" ]]; then
        continue
    fi
    seen_dirs["$stack_dir"]=1

    printf '\n%s==> %s%s\n' "${BOLD}${BLUE}" "$stack_name" "$RESET"

    # Print the command without changing containers.
    if $DRY_RUN; then
        printf '    (cd %q && docker compose up -d --pull always --remove-orphans)\n' "$stack_dir"
        continue
    fi

    started_at=$SECONDS

    # Run in a subshell so cd only affects this stack.
    # Orphan cleanup removes containers for commented-out or deleted services.
    if (cd "$stack_dir" && docker compose up -d --pull always --remove-orphans); then
        printf '%s==> %s finished in %ss%s\n' "$GREEN" "$stack_name" "$((SECONDS - started_at))" "$RESET"
    else
        printf '%s==> %s failed%s\n' "$RED" "$stack_name" "$RESET" >&2
        failed_stacks+=("$stack_name")
    fi
done

# Dry runs stop here without printing an update summary.
if $DRY_RUN; then
    printf '\n%sDry run complete; no changes made.%s\n' "$YELLOW" "$RESET"
    exit 0
fi

# Exit non-zero if any stack failed, after attempting every stack.
if ((${#failed_stacks[@]} > 0)); then
    printf '\n%sFailed stacks: %s%s\n' "$RED" "${failed_stacks[*]}" "$RESET" >&2
    exit 1
fi

printf '\n%sAll stacks updated successfully.%s\n' "$GREEN" "$RESET"
