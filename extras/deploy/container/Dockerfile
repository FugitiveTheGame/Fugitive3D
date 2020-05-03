FROM ubuntu:focal

# Copy all needed files into the root directory inside the container.
COPY ./Godot_v3.2.1-stable_linux_server.64 /root
COPY ./data.pck /root
COPY ./run.sh /root

WORKDIR /root

# Expose 31000 TCP/UDP outside the container.
EXPOSE 31000/tcp
EXPOSE 31000/udp

CMD "/root/run.sh"
