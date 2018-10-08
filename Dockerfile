FROM dceoy/oanda-cli:latest

ADD https://github.com/dceoy/fract/archive/master.tar.gz /tmp/fract.tar.gz

RUN set -e \
      && pip install -U --no-cache-dir /tmp/fract.tar.gz \
      && rm -rf /tmp/fract

ENTRYPOINT ["fract"]
