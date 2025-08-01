FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git subversion \
    libncurses5-dev libncursesw5-dev libssl-dev \
    python3-distutils python3-setuptools \
    rsync unzip zlib1g-dev file wget curl sudo \
    swig libpython3-dev time \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

RUN git clone https://github.com/openwrt/openwrt.git && \
    cd openwrt && \
    git checkout openwrt-23.05

WORKDIR /home/builder/openwrt

RUN ./scripts/feeds update -a && ./scripts/feeds install -a

CMD ["/bin/bash"]
