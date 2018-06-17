FROM python:latest

RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && pip install -U --no-cache-dir pip \
        git+https://github.com/oanda/oandapy.git \
        git+https://github.com/dceoy/fract.git

ENTRYPOINT ["fract"]
