# alpine_base_aca

Alpine-based Docker image with Ansible, Terraform, Docker CLI, Go, and Python data tools.
Multi-arch: `linux/amd64` and `linux/arm64`.

## Components

| Component | Version |
|-----------|---------|
| Alpine Linux | 3.22.4 |
| Python | 3.12.13 |
| Ansible | 13.7.0 (core 2.20.6) |
| avisdk | 32.1.1 |
| pandas | 3.0.3 |
| Terraform | 1.15.5 |
| Docker CLI | 29.5.2 |
| Go | 1.26.3 |
| vmware.alb collection | 32.1.1 |

## Usage

```bash
docker pull aca2328/alpaca:latest
docker run -it aca2328/alpaca:latest
```

## Build

```bash
export DOCKER_PASSWORD=your_token
./build.sh
```
