Check AI4OS-Hub artifact
============================================
<img style="vertical-align:middle" src="https://avatars.githubusercontent.com/u/137064113?s=200&v=4" height="120" alt="AI4EOSC logo"/>

This repository is intended for a collection of scripts to test final artifacts of users contributing to the [AI4OS](https://dashboard.cloud.ai4eosc.eu/marketplace).
The scripts will be executed at the end of the Jenkins pipeline to check if the final Docker image behaves as expected.

### `check-artifact`

Starts the given Docker image, waits until the service is ready, and verifies
that it responds:

```bash
bash check-artifact <docker_image> [container_port]   # port: 5000 = DEEPaaS API, 8888 = IDE
```

Readiness behavior:
- if the image defines a Docker `HEALTHCHECK`, the script waits for the
  container to become `healthy` (recommended: give the healthcheck a
  `--start-period` long enough to cover first-boot installations)
- otherwise it polls the mapped port directly with `curl`

Tuning via environment variables:

| Variable         | Default | Meaning                                            |
|------------------|---------|----------------------------------------------------|
| `CHECK_MAX_WAIT` | `300`   | overall readiness budget in seconds                |
| `CHECK_SLEEP`    | `10`    | seconds between readiness polls                    |

The overall budget (rather than a fixed number of tries) accommodates slow
first boots, e.g. `deep-start -j` pip-installing JupyterLab extensions at
container start.

@2019-2024

