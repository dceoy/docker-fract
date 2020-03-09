FROM dceoy/oanda-cli:latest

RUN set -e \
      && pip install -U --no-cache-dir \
            https://github.com/dceoy/fract/archive/master.tar.gz

ENTRYPOINT ["fract"]
