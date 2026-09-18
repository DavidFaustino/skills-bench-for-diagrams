# Environment for running the benchmark, not for using the skills.
# A skill that requires Docker stops being portable; this container exists only so that
# anyone can reproduce the five results without assembling five toolchains by hand.
#
#   docker build -t skills-bench-for-diagrams .
#   docker run --rm -t -v "$PWD/benchmark-diagrams/results:/app/benchmark-diagrams/results" skills-bench-for-diagrams
#
FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    CHROMIUM_PATH=/usr/bin/chromium \
    VENDOR_DIR=/opt/vendor \
    PYTHONDONTWRITEBYTECODE=1

# graphviz and headers: runs 01 and 02. chromium: run 04. xvfb: the draw.io export.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl \
      python3 python3-venv python3-dev \
      graphviz libgraphviz-dev pkg-config build-essential \
      chromium \
      xvfb xauth libgbm1 libasound2 libnss3 libgtk-3-0 \
 && rm -rf /var/lib/apt/lists/*

# uv, used for the Python environments
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# draw.io desktop: the export in run 05. Without it the benchmark still validates the .drawio.
ARG DRAWIO_VERSION=31.4.5
# TARGETARCH is filled in by BuildKit (amd64 or arm64)
ARG TARGETARCH
RUN curl -fsSL -o /tmp/drawio.deb \
      "https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/drawio-${TARGETARCH}-${DRAWIO_VERSION}.deb" \
 && (apt-get update && apt-get install -y --no-install-recommends /tmp/drawio.deb \
     || echo "draw.io not installed on this architecture; run 05 will only validate") \
 && rm -f /tmp/drawio.deb && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY benchmark-diagrams/install.sh benchmark-diagrams/bench.sh ./benchmark-diagrams/
COPY benchmark-diagrams/scripts/ ./benchmark-diagrams/scripts/
RUN chmod +x benchmark-diagrams/install.sh benchmark-diagrams/bench.sh benchmark-diagrams/scripts/*.py

# The tools are cloned from source, at pinned commits. Nothing is vendored into the image.
RUN ./benchmark-diagrams/install.sh

COPY . .

# bench.sh invokes xvfb only in the step that needs it, the draw.io export.
ENTRYPOINT ["./benchmark-diagrams/bench.sh"]
