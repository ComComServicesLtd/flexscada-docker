FROM alpine:3.5
MAINTAINER FlexSCADA Systems <support@flexscada.com>

RUN apk --update add --no-cache bash libstdc++ libgcc libcurl boost-system \
  && rm -rf /var/cache/apk/*

#RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
#RUN sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config
#RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
#RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config
#RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config
#RUN sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config
#RUN /usr/bin/ssh-keygen -A
#RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key




#EXPOSE 22
#CMD ["/usr/sbin/sshd","-D"]


COPY ./run.sh /run.sh
COPY ./flexscada_d /usr/bin/flexscada_d
COPY ./index.html /index.html
COPY ./app.js /app.js

EXPOSE 7001
EXPOSE 8000
EXPOSE 8001

WORKDIR /flexscada
ENTRYPOINT [ "/run.sh" ]

#build with docker build -t flexscada
