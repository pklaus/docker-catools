# docker-catools

A compact distribution of common EPICS Channel Access and PV Access tools via Docker images.

Available on the Docker Hub at: [/r/pklaus/catools](https://hub.docker.com/r/pklaus/catools).

## Available Tools

The following executables from EPICS are part of this Docker image:

```
acctst      caEventRate  caput    iocLogServer  pvinfo
aitGen      caRepeater   casw     makeBpt       pvlist
antelope    ca_test      catime   msi           pvmonitor
ascheck     caget        e_flex   p2p           pvput
caConnTest  cainfo       excas    pvcall        softIoc
caDirServ   camonitor    genApps  pvget         softIocPVA
```

## Tags

There are two flavours of the images available:

* `scratch` (aka `latest`) **no** underlying Linux system, just executables and libraries,
* `debian` based on Debian (slighly larger)

Each tag is built for multiple architectures (`linux-{amd64,386,arm64,arm/v7}`).

## Examples

**caget** of a process variable from an IOC in the (Docker internal) network `docker-epics`.

```
docker run \
  --rm \
  --network docker-epics \
  pklaus/catools \
  caget FAIR:CBM:MVD:YOUR:PV
```

**camonitor** works too, but for being able to quit <kbd>Ctrl + c</kbd> the process needs to run
with a PID higher than 1 inside the container. This can be reached by wrapping the
call in a shell command or by specifying `--pid=host` in the docker run statement:

```
docker run \
  --rm \
  --pid host \
  --network docker-epics \
  pklaus/catools \
  camonitor FAIR:CBM:MVD:YOUR:PV
```

*If such a command was accidentally started without specifying a different PID it won't quit
with <kbd>Ctrl + c</kbd>, the terminal can be disattached from the container using
<kbd>Ctrl + p</kbd> <kbd>Ctrl + q</kbd> and the container can then be killed with
`docker kill` using the hash revealed by `docker ps`.*

When using a more elaborate tool such as the `softIoc`, I recommend to use the
`debian` flavour of the images.
