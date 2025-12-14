FROM alpine:3.23.0
# Set root  password. Conventionally Azure App Service expectes root:Docker! for ssh-ing into the container
RUN echo "root:Docker!" | chpasswd

# Prepare ssh server. with this ssh server we can connect to it in our pipeline and run tests.
RUN apk update && apk add --no-cache openssh bash
# alpine does not create this directory by default
RUN mkdir /var/run/sshd 
COPY sshd_config /etc/ssh/sshd_config
# this creates all required ssh keys (/etc/ssh/ssh_host_rsa_key, ...)
RUN ssh-keygen -A
EXPOSE 2222

COPY init_container.sh /init_container.sh
RUN chmod +x /init_container.sh

ENTRYPOINT ["/init_container.sh"]