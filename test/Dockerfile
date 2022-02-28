FROM amd64/ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y python3-pip python3-venv git sudo emacs-nox
RUN adduser --shell /bin/bash crossjam
RUN usermod -aG sudo crossjam
RUN echo 'crossjam ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/crossjam
USER crossjam
RUN mkdir /home/crossjam/.ssh && chmod go-rwx /home/crossjam/.ssh
WORKDIR "/home/crossjam"
CMD ["/bin/bash", "-l"]
