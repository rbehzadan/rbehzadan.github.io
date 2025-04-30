---
title: "A Clean Naming Convention for Docker Build & Push Workflows"
date: 2025-04-29
description: "How I standardized my GitHub and Gitea workflow file names for Docker image building and pushing — making my projects cleaner and easier to maintain."
tags: ["docker", "gitea", "github actions", "ci/cd", "best practices"]
categories: ["DevOps", "Best Practices"]
cover:
  image: "img/post-0003-cover.jpg"
  hidden: false
showToc: false
---

# A Clean Naming Convention for Docker Build & Push Workflows

In my development projects, I often need to build and push Docker images automatically using CI workflows.  
Depending on the project, the architecture, and the target registry, the workflows can vary quite a bit.  
Sometimes I use **Gitea Actions**, sometimes **GitHub Actions**, and in some projects, even **both**.

As the number of workflows grew, I realized that my workflow file names were getting messy and inconsistent.  
So, I decided to come up with a **simple, scalable naming convention** — one that would work cleanly whether I'm using GitHub, Gitea, or any other CI platform.

---

## Requirements

In my projects, the workflows need to handle different combinations of:

- **Build Architecture:**
  - **Native** build (the architecture of the runner, e.g., `amd64` or `arm64`)
  - **Multi-architecture** build (`amd64` and `arm64` together)

- **Target Registry:**
  - Docker Hub
  - GitHub Container Registry (GHCR)
  - My **own private registry** (`dcr.behzadan.com`)

This gives a few different combinations. I wanted the filenames to clearly reflect **what each workflow does** without needing to open the file and check.

---

## Naming Convention

Here’s the naming pattern I chose:

```text
[build-type]-[target-registry]-push.yaml
```

Where:
- `build-type`: `native` or `multiarch`
- `target-registry`: `dockerhub`, `ghcr`, or `dcr`
- Always end with `push.yaml` to indicate that the workflow builds **and pushes** the image.

---

## Examples

Here are some examples following this convention:

| Build Type  | Registry               | Workflow File Name               | Description |
|-------------|-------------------------|-----------------------------------|-------------|
| Native      | Private Registry (DCR)   | `native-dcr-push.yaml`            | Build native architecture and push to `dcr.behzadan.com` |
| Multi-arch  | Private Registry (DCR)   | `multiarch-dcr-push.yaml`         | Build multi-arch and push to `dcr.behzadan.com` |
| Native      | Docker Hub               | `native-dockerhub-push.yaml`      | Build native and push to Docker Hub |
| Multi-arch  | Docker Hub               | `multiarch-dockerhub-push.yaml`   | Build multi-arch and push to Docker Hub |
| Native      | GitHub Container Registry| `native-ghcr-push.yaml`           | Build native and push to GHCR |
| Multi-arch  | GitHub Container Registry| `multiarch-ghcr-push.yaml`        | Build multi-arch and push to GHCR |

---

## Benefits

- **Readable:** At a glance, I can tell what each workflow does.
- **Scalable:** As I add new workflows, the naming stays consistent.
- **Cross-platform:** Works the same for Gitea and GitHub workflows.
- **Future-proof:** If I later add "staging" and "production" environments, I can easily extend the convention to:

  ```text
  [build-type]-[target-registry]-[env]-push.yaml
  ```

  Example: `multiarch-dcr-prod-push.yaml`, `native-ghcr-staging-push.yaml`

---

## Example: My Current Workflows

Here’s how it looks in a real project:

```bash
.gitea/workflows/
├── native-dcr-push.yaml
└── multiarch-dcr-push.yaml
```

Each file contains a workflow that builds and pushes the image based on its architecture and registry.

Inside each YAML file, I also give a nice human-readable `name` field like this:

```yaml
name: Native Build and Push to DCR
```
or
```yaml
name: Multi-Arch Build and Push to DCR
```

---

## Bonus: Future Improvements

To make things even cleaner and more DRY (Don't Repeat Yourself), it's possible to:

- **Create a reusable workflow template** with inputs like `build-arch` and `registry`
- **Use matrix builds** to cover multiple architectures dynamically
- **Separate build and push steps** when needed for more complex pipelines
- **Use environment files** or secrets management to switch registries safely

This way, a single workflow could handle multiple build strategies by simply passing parameters, instead of duplicating similar workflows.

---

## Final Thoughts

It may seem like a small thing, but **clear and consistent workflow naming** saves a lot of confusion and time in the long run — especially when switching between GitHub and Gitea, or when revisiting a project months later.

If you find yourself juggling multiple build targets and registries, I highly recommend adopting a similar convention!

---

