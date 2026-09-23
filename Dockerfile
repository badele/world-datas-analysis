
FROM node:22-bookworm-slim AS precommit
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 python3-venv git git-lfs \
  && python3 -m venv /opt/precommit-venv \
  && /opt/precommit-venv/bin/pip install --no-cache-dir pre-commit \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV PATH="/opt/precommit-venv/bin:$PATH"
CMD ["pre-commit", "run", "--all-files"]

FROM	ubuntu:24.04
ENV	DEBIAN_FRONTEND	noninteractive
COPY	requirements.txt	requirements.txt
COPY	importer/requirements.sh	requirements.sh
RUN	chmod +x requirements.sh
RUN	./requirements.sh
RUN	rm -rf /var/lib/apt/lists/* \
	&& apt-get clean \
	&& rm -rf requirements.*
