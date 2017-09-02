FROM alpine:3.6

EXPOSE 2022

VOLUME ["/data"]
ENV poll_users=true

RUN apk add --no-cache openssh openssh-sftp-server
COPY config/sshd_config /etc/ssh/sshd_config
COPY bin/* /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/setup_environment"]

