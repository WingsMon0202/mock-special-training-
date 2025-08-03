# 🐳 OpenWrt Builder Docker Image


This Docker image provides a **fully preconfigured OpenWrt build environment** (toolchain, feeds, and scripts) so users can easily build OpenWrt packages without setting up the environment themselves.  

##  Table of Contents
- [  OpenWrt Builder Docker Image](#openwrt-builder-docker-image)
  - [Image Contents](#image-contents)
  - [How to Use](#how-to-use)
    - [1 Pull the image from Docker Hub](#1-pull-the-image-from-docker-hub)
    - [2 Run the container](#2-run-the-container)
    - [3 Directory Structure inside the Container](#3-directory-structure-inside-the-container)
    - [4 Build a Package](#4-build-a-package)
    - [5 Install the `.ipk` Package on OpenWrt](#5-install-the-ipk-package-on-openwrt)
  - [Customizing Builds](#customizing-builds)
  - [Information](#information)
- [How to I make that](#how-to-i-make-that)
  - [Achitechture](#achitechture)
  - [GIT](#git)
  - [Step by step I do](#step-by-step-i-do)
    - [1. Write a Dockerfile to build system Openwrt](#1-write-a-dockerfile-to-build-system-openwrt)
    - [2. Build image from Dockerfile](#2-build-image-from-dockerfile)
    - [3. Creat volume](#3-creat-volume)
    - [4. Creat container and mount volume](#4-creat-container-and-mount-volume)
    - [5. Create custom feed in local repo](#5-create-custom-feed-in-local-repo)
    - [6. Config file feed.config](#6-config-file-feedconfig)
    - [7. Update and install feed](#7-update-and-install-feed)
    - [8. Chose custem package in menu anh remake](#8-chose-custem-package-in-menu-anh-remake)
    - [9. Commit the container](#9-commit-the-container)
    - [10. Push the image to Docker Hub](#10-push-the-image-to-docker-hub)


## Image Contents
-  Ubuntu base (with all OpenWrt build dependencies installed)  
-  OpenWrt toolchain & scripts  
-  Integrated custom feed `myfeed` (includes the `check-python` package)  
-  Supports building `.ipk` packages for `aarch64_cortex-a72`  

---

## How to Use

### 1 **Pull the image from Docker Hub**
```bash
docker pull wingsmon0202/openwrt-builder-saved:final
```

### 2 **Run the container**
```bash
docker run -it --name openwrt-build wingsmon0202/openwrt-builder-saved:final sh
```

Optional: **mount an external directory** so your code/packages persist even if the container is removed:
```bash Config file feed.config
In container, I config file feed.config.defaut where clone feeds
docker run -it --name openwrt-build -v $(pwd)/myfeed:/feeds/myfeed  wingsmon0202/openwrt-builder-saved:final sh
```

---

### 3 **Directory Structure inside the Container**
- `/home/builder/openwrt` → OpenWrt source code  
- `/feeds/myfeed` → custom feed for packages  
- `/home/builder/openwrt/bin/packages` → location of built `.ipk` packages  
- `/home/builder/openwrt/bin/packages/aarch64_cortex-a72/myfeed/` -> location `.ipk` python-check package

---

### 4 **Build a Package**
For example, to build the `check-python` package:
```bash
cd /home/builder/openwrt
make package/feeds/myfeed/python-check/compile V=s
```

The resulting `.ipk` file will be located in:
```
/home/builder/openwrt/bin/packages/aarch64_cortex-a72/myfeed/
```

---

### 5 **Install the `.ipk` Package on OpenWrt**
Copy the `.ipk` file to your OpenWrt device (via SCP or USB):
```bash
scp check-python_1.0-1_aarch64_cortex-a72.ipk root@192.168.1.1:/tmp
```

Then SSH into the router and install it:
```bash
opkg install /tmp/check-python_1.0-1_aarch64_cortex-a72.ipk
```

---

##  Customizing Builds
- Modify `feeds/myfeed` to add your own packages.  
- Use a mounted volume when running the container to preserve code & packages between builds.  

---

## Information
-  **Maintainer:** WingsMon0202  
-  **Docker Hub:** [wingsmon0202/openwrt-builder](https://hub.docker.com/repository/docker/wingsmon0202/openwrt-builder-saved)  
-  **Tag:** `final`

# How to I make that 
## Achitechture
```mermaid
+-----------------------+
|     Docker Hub        |
|-----------------------| 
|(wingsmon/openwrt      |
|  -builder-saved:final)|
+--------+--------------+
         ^
         | docker push/pull
         v
+--------+---------------------+
|       Docker Image           |   <- Image commit container build
|------------------------------|
|openwrt-builderbuilder-saved  |
+--------+---------------------+
         |
         | docker run (mount volume)
         v
+--------+---------------------------+
|        Docker Container            |
|------------------------------------|
|  (openwrt-container-feed)          |
|                                    |
|   - OpenWrt Buildroot              |
|   - Feeds (myfeed)                 |
|   - Compiler (cross for Pi)        |
|   - Built .ipk packages            |
|                                    |
| /home/builder/openwrt/feeds/myfeed |
|          ^                         |
|          | bind mount (volume)     |
+----------+-------------------------+
           |
           v
+----------+-------------------------+
|     Host Machine                   |
|                                    |
|   - Docker Engine                  |
|   - External Volume:               |
|       ~/docker/myfeed              |
|                                    |
+------------------------------------+
```
## GIT
This project is managed by git. I created a git repo on my host by `git init`. I create new branch and checkout it.

*Directory structure:*
```bash
--docker/
  |---- openwrt-docker/
            |---Dockerfile
            |---myfeed/
            |     |---check-python
            |                |----Makefile
            |                |----src/
            |                       |---python.c
            |                       |---Makefile
            |------.git
```

```
git checkout -b feature/python-version-check
```
Stages all changes, commits with a descriptive message, and pushes the branch to the remote repository
```
git add .
git commit -m "mock project"
git push origin feature/python-version-check
```
Tags the current commit as v1.0-python-check and pushes the tag to the remote repository. This marks the first stable release of the python-check feature.
```
git tag v1.0-python-check
git push origin v1.0-python-check
```

![git](git.png)

---

## Step by step I do
### 1. Write a Dockerfile to build system Openwrt
This is Dockerfile
```bash
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

```
This Dockerfile builds a complete OpenWrt build environment based on Ubuntu 22.04. It first sets DEBIAN_FRONTEND=noninteractive to avoid installation prompts, then installs all required toolchains and dependencies such as compilers (gcc, g++, clang, bison, flex), libraries (libssl-dev, ncurses), Python tools, and common utilities (wget, curl, rsync) needed to compile OpenWrt and its packages. A non-root user builder is created for safety, with passwordless sudo access for convenience. The OpenWrt source code is cloned from the official GitHub repository and switched to the stable openwrt-23.05 branch, after which all feeds are updated and installed to bring in core packages. The working directory is set to /home/builder/openwrt, and the container defaults to launching a bash shell, allowing users to jump straight into the OpenWrt build environment and start compiling firmware or custom .ipk packages.

---

### 2. Build image from Dockerfile 
```bash
docker build -t openwrt-builder-saved .
```
![build-image](build-image.png "build image with docker file")
---
### 3. Creat volume
After that I check the image by `docker image ls` and I can see new image name openwrt-builder-saved and then I creat a new volume. 
```bash
 docker volume creat openwrt-feed
```
I check the new volume by ```docker volume ls``` 

![volume](volume.png "volume in my docker")

---
### 4. Creat container and mount volume 
In host I creat a local repo for my custom feed at `docker/myfeed`
```bash
git init
```
I creat container by `run` and mount volume at `/feeds/myfead` with a local repo in my host at `/docker/myfeed/`
```bash
docker run -it \
  --name openwrt-container \
  -v ~/docker/myfeed:/feeds/myfeed \
  openwrt-builder-saved /bin/bash
```
---
### 5. Create custom feed in local repo
In local repo mount with container I write a C application to execute a system call to get Python 3.9 version.

*Directory structure:*

```bash
---myfeed
    |---python-check/
    |   |------Makefile
    |   |------src/
    |            |----Makefile
    |            |----python.c
    |---.git
```
This is my `python-check.c` follow:

- Uses system("which python3.9 > /dev/null 2>&1") to check if Python 3.9 exists.
- Uses popen("python3.9 --version", "r") to capture the version output.
- Prints the version to console.
- Writes the version to /tmp/python_ver.log.
- Returns non-zero exit code if Python 3.9 is not found.
```
#include <stdio.h>
#include <stdlib.h>

int main() {
    if (system("which python3.9 > /dev/null 2>&1") != 0) {
        printf("Error: Python 3.9 not found\n");
        return 1;
    }

    FILE *fp = popen("python3.9 --version", "r");
    if (fp == NULL) {
        printf("Error: Failed to run command\n");
        return 1;
    }

    char buffer[128];
    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        printf("Detected Python Version: %s", buffer);
        FILE *log = fopen("/tmp/python_ver.log", "w");
        if (log != NULL) {
            fprintf(log, "%s", buffer);
            fclose(log);
        }
    }
    pclose(fp);
    return 0;
}
```

In this I have 2 *Makefile*, in `myfeed/Python-check` I write Makefile for custom feed:
```
include $(TOPDIR)/rules.mk
PKG_NAME:=check-python
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/check-python
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Check Python 3.9 version tool
  DEPENDS:=+libc
endef

define Package/check-python/description
 A simple tool to check Python 3.9 version and log to /tmp/python_ver.log
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		check_python
endef

define Package/check-python/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/check_python $(1)/usr/bin/
endef

$(eval $(call BuildPackage,check-python))
```
*This OpenWrt Makefile mainly does the following:*
- Defines the package metadata – sets name (PKG_NAME), version, section, category, description, and dependencies (libc).
- Prepares the build directory – creates $(PKG_BUILD_DIR) and copies source files from src/ into it.
- Compiles the source code – runs make with OpenWrt’s cross-compilation toolchain (TARGET_CC, TARGET_CFLAGS, TARGET_LDFLAGS) to build the check_python binary.
- Installs the compiled binary – places check_python into /usr/bin in the target root filesystem.
- Registers the package with OpenWrt build system – $(eval $(call BuildPackage,check-python)) makes sure OpenWrt can build and generate the .ipk package.

In `myfeed/Python-check/src/Makefile` I write for cros-compile the C code 
```CC ?= gcc
CFLAGS ?= -Wall -O2

all: check_python

check_python: python.c
	$(CC) $(CFLAGS) -o check_python python.c

clean:
	rm -f check_python
```

When I When I'm done coding, I commit it to the repo and then my `volume` will automatically update with my changes.

---
### 6. Config file feed.config
In container, I config file feed.config.defaut where clone feeds. I add a new line is a path mount with volume feed in container.

```
src-git myfeed file:///feeds/myfeed
```

![feed](feed.png "/feed.config.default")

---
### 7. Update and install feed
I upadate and install new feed with:
```
./scripts/feeds update myfeed
./scripts/feeds install myfeed

```
![update](update.png)

when use `./scripts/feeds update myfeed` the Openwrt clone the package inside folder `openwrt/feeds/` and creat a index file

![update-feed](feed2.png)

When use `./scripts/feeds install myfeed` The openWRT read all feed in `openwrt/feeds/` and create simulink in `openwrt/package/feeds/`. Finaly the build system can choses when `make config`

![install](install.png)

---
### 8. Chose custem package in menu anh remake

Open menu config with `make menuconfig` go to `utilite` and chose `check-python`.
![menuconfig](menu.png "make menuconfig")

```
make -j$(nproc)
```

Custom feed will compile gen to a .ipk and add into rootfs. Final ipk in `/home/builder/openwrt/bin/packages/aarch64_cortex-a72/myfeed/`
 ![ipk](pwd.png)

---
### 9. Commit the container 
Finaly I conrectly the custem build in package and I snapshot of the container. 
```
docker commit openwrt-container-feed openwrt-builder-saved:final
``` 
Check with `docker image ls`

![commit](commit.png "final image")
---
### 10. Push the image to Docker Hub 
To push code to docker hub i have to login to docker hub with my github account. Use `docker login`

![login](docke.png)

Use `tag` follow `docker tag <IMAGE_ID> <dockerhub_username>/<repo_name>:<tag>`
and push the image
```
docker push wingsmon0202/openwrt-builder-saved:final
 ```
When complete push, in docker hub will have a repo like that
![dockerhub](dockerhub.png)
