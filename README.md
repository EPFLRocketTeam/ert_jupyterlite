# Multilingual JupyterLite

A static JupyterLab-style learning site with Python, R, JavaScript, and C++ kernels compiled to WebAssembly. The kernels run in each visitor’s browser; the deployed container serves generated files with Nginx and does not execute notebooks or provide a Jupyter server, database, or authentication service.

## Languages and limitations

- **Python** uses `xeus-python`, with NumPy and Matplotlib pre-installed.
- **R** uses `xeus-r`.
- **JavaScript** uses `xeus-javascript` in the browser; this is not Node.js and does not provide Node APIs or arbitrary server-side access.
- **C++** uses `xeus-cpp` compiled to WebAssembly; it is not a full native operating system and cannot use arbitrary host system libraries.

The first visit to a kernel may download sizable WebAssembly/package assets. Actual memory, CPU, browser compatibility, and available APIs depend on the visitor’s device and browser. Users need a modern browser with WebAssembly enabled. Code execution and notebook storage happen locally in the browser. Browser storage can be cleared or unavailable in private/restricted sessions, so download important notebooks and outputs for backup. This deployment does not synchronize notebooks between devices or users.

## Repository layout

- `Dockerfile` — multi-stage build; JupyterLite build tools are discarded from the runtime image.
- `docker-compose.yml` — Dokploy-ready service, with no host port mapping or persistent volume.
- `environment.yml` — Emscripten/WebAssembly runtime packages for the four browser kernels.
- `requirements-build.txt` — pinned host-side static-site build packages (not notebook kernels).
- `nginx.conf` — static-file serving, WebAssembly MIME type, and `/` redirect to `/lab/`.
- `notebooks/` — welcome page and runnable examples for each language.

## Build and run locally

Docker and the Compose plugin are required. Build and start the site:

```sh
docker compose up --build -d
```

For local testing only, publish port 80 on the host by temporarily adding this Compose override to the service:

```yaml
ports:
  - "8080:80"
```

Then browse to `http://localhost:8080/` (which redirects to `/lab/`). Remove the temporary port mapping before deploying through Dokploy. To check Compose configuration, run `docker compose config`; to stop the service, run `docker compose down`.

The Docker build assembles all notebooks and packages in the browser environment into `/site`. The final image contains Nginx and that static output only. It does not include Python, micromamba, or a server-side kernel runtime.

## Deploy with Dokploy

1. Push this repository to a Git provider accessible to Dokploy.
2. Create a Compose application in Dokploy and connect the repository/branch. Use the repository root as the Compose file directory so Dokploy finds `docker-compose.yml` and `Dockerfile`.
3. Deploy/build the application. The Compose service is named `jupyterlite` and listens on port `80` inside the container/network.
4. In Dokploy’s domain or proxy settings, route the chosen hostname to service `jupyterlite`, port `80`, and enable HTTPS/automatic certificates.
5. Open the hostname; `/` redirects to `/lab/`.

The Compose configuration intentionally uses `expose` rather than publishing a host port. Dokploy’s internal proxy provides access. There are no runtime volumes because this is an immutable static site; visitor notebook changes are held client-side, not on the container.

## Add notebooks or packages

- Put additional `.ipynb` files in `notebooks/`; they are included in the next image build.
- Open each language demo with its matching kernel (`Python (WebAssembly)`, `R (WebAssembly)`, `JavaScript (WebAssembly)`, or `C++20 (WebAssembly)`) selected from the notebook kernel menu before running cells. The site build adds the available browser kernels to the launcher; a notebook with no saved kernelspec will otherwise inherit JupyterLite's default kernel.
- Add packages required in the browser to `environment.yml`, choosing packages available for the `emscripten-wasm32` platform from the configured Emscripten Forge/conda-forge channels. Do not put native OS kernels in this file.
- Rebuild/redeploy the image after content or dependency changes. The browser package environment is packaged during the static build; package availability is limited to WebAssembly-compatible builds.
- The host-side builder dependencies belong in `requirements-build.txt` and are separate from `environment.yml`.

## Verification

The intended deployment check is `docker compose config`, followed by `docker compose build`. After a successful build, verify `/` redirects to `/lab/`, Nginx serves the Lab assets and `.wasm` with `Content-Type: application/wasm`, and all four language kernels appear in the launcher/kernel list. Run each example in a supported browser; Docker image construction alone does not prove notebook execution in every browser/device.
