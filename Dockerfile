FROM python:latest

ADD https://github.com/oanda/oandapy/archive/master.tar.gz /tmp/oandapy.tar.gz
ADD https://github.com/dceoy/fract/archive/master.tar.gz /tmp/fract.tar.gz

RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && pip install -U --no-cache-dir pip /tmp/oandapy.tar.gz /tmp/fract.tar.gz \
      && rm -rf /tmp/oandapy.tar.gz /tmp/fract

ENTRYPOINT ["fract"]
