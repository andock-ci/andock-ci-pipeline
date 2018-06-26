FROM docksal/cli:2.0-php7.1

RUN mkdir -p /usr/local/bin
COPY bin/acp.sh /usr/local/bin/acp

RUN chmod +x /usr/local/bin/acp
RUN acp _install-pipeline
