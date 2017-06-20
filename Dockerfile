FROM python

ADD https://github.com/oanda/oandapy/archive/master.tar.gz /tmp/oandapy.tar.gz
ADD https://github.com/dceoy/fract/archive/master.tar.gz /tmp/fract.tar.gz

RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && apt-get -y update \
      && apt-get -y upgrade \
      && apt-get clean

RUN set -e \
      && pip install -U pip \
      && pip install -U /tmp/oandapy.tar.gz /tmp/fract.tar.gz \
      && rm -rf /tmp/*

ENTRYPOINT ["fract"]
