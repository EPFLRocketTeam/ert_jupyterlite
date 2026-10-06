# Build JupyterLite and its WebAssembly kernel assets; serve only static files at runtime.
FROM mambaorg/micromamba:2.0.5 AS builder

USER root
WORKDIR /workspace

COPY requirements-build.txt ./requirements-build.txt
RUN micromamba create --yes --name site-build --channel conda-forge python=3.12 pip \
    && micromamba run --name site-build python -m pip install --no-cache-dir -r requirements-build.txt \
    && micromamba clean --all --yes

COPY environment.yml ./environment.yml
COPY notebooks/ ./notebooks/

RUN micromamba run --name site-build jupyter lite build \
    --contents notebooks \
    --output-dir /site \
    --XeusAddon.environment_file=environment.yml

FROM nginx:1.27.5-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /site/ /usr/share/nginx/html/
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
