#Build mhsendmail
FROM docksal/cli:2.0-php7.1

RUN mkdir -p /usr/local/bin
COPY bin/acp.sh /usr/local/bin/acp

RUN chmod +x /usr/local/bin/acp
RUN acp _install-pipeline

#RUN curl -fsSL https://raw.githubusercontent.com/andock-ci/pipeline/master/install-pipeline | sh
#COPY startup.sh /opt/startup.sh
#ENTRYPOINT ["/opt/startup.sh"]
#RUN ["chmod", "+x", "/opt/startup.sh"]