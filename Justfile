set shell := ["bash", "-uo", "pipefail", "-c"]

project_root := justfile_directory()

build target="":
    mkdir -p .cache/cargo/{registry,git}
    docker build --tag wifi-connect-builder -f Dockerfile "{{project_root}}"
    docker run --rm \
        -v "{{project_root}}":/workspace \
        -v "{{project_root}}/.cache/cargo/registry":/usr/local/cargo/registry \
        -v "{{project_root}}/.cache/cargo/git":/usr/local/cargo/git \
        -w /workspace \
        wifi-connect-builder {{target}}

ui:
    docker run --rm -v "{{project_root}}/ui":/workspace -w /workspace node:18 bash -uo pipefail -c "npm ci && npm run build"

clean:
    rm -rf target ui/node_modules ui/build
