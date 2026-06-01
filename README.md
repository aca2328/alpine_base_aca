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

## AVI multi-version support

The last 3 AVI releases are pre-installed for both Ansible and Terraform:

| AVI Version | vmware.alb collection | Terraform provider |
|-------------|----------------------|--------------------|
| 32.1.1 | `/opt/avi-collections/32.1.1` | pre-cached |
| 31.2.2 | `/opt/avi-collections/31.2.2` | pre-cached |
| 30.2.7 | `/opt/avi-collections/30.2.7` | pre-cached |

**Ansible** — select the collection version via `ANSIBLE_COLLECTIONS_PATH`:
```bash
ANSIBLE_COLLECTIONS_PATH=/opt/avi-collections/31.2.2 ansible-playbook site.yml
```

**Terraform** — the provider cache (`TF_PLUGIN_CACHE_DIR`) is pre-seeded. Terraform picks the right version automatically based on your `required_providers` constraint:
```hcl
terraform {
  required_providers {
    avi = {
      source  = "vmware/avi"
      version = "~> 31.2"
    }
  }
}
```

**Python avisdk** — a single install of `32.1.1` covers all controller versions (the SDK is backwards-compatible).

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
