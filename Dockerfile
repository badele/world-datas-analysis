
FROM	ubuntu:24.04
ENV	DEBIAN_FRONTEND	noninteractive
COPY	requirements.txt	requirements.txt
COPY	importer/requirements.sh	requirements.sh
RUN	chmod +x requirements.sh
RUN	./requirements.sh
RUN	rm -rf /var/lib/apt/lists/* \
	&& apt-get clean \
	&& rm -rf requirements.*
