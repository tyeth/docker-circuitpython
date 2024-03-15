FROM ubuntu:24.04

ARG CIRCUITPYTHON_VERSION="9.0.0-rc.1"
ARG PORT="espressif"
ARG BOARD="adafruit_feather_esp32_v2"

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y \
  && apt-get install -y wget \
  && wget -O netselect.deb http://http.us.debian.org/debian/pool/main/n/netselect/netselect_0.3.ds1-28+b1_`dpkg --print-architecture`.deb \
  && dpkg -i netselect.deb \
  && rm netselect.deb \
  && sed -r -i -e "s#http://(archive|security)\.ubuntu\.com/ubuntu/?#$(netselect -v -s1 -t20 `wget -q -O- https://launchpad.net/ubuntu/+archivemirrors \
  | grep -P -B8 "statusUP|statusSIX" \
  | grep -o -P "http://[^\"]*"` \
  | grep -P -o 'http://.+$')#g" /etc/apt/sources.list

RUN \
  apt-get install -y build-essential pkg-config libffi-dev wget \
  git gettext python3 python3-pip python-is-python3 \
  python3.12-venv ninja-build cmake libusb-1.0-0-dev

RUN git clone https://github.com/adafruit/circuitpython.git

WORKDIR /circuitpython

RUN \
  git checkout "${CIRCUITPYTHON_VERSION}"

# Remove this line to limit number of displays to 1!
RUN \
  sed -i '/#define CIRCUITPY_DISPLAY_LIMIT (1)/s/(1)/(5)/' py/circuitpy_mpconfig.h

RUN \
  python -m venv venv \
  && . venv/bin/activate \
  && pip install --no-cache-dir -r requirements-dev.txt -r requirements-doc.txt \
  && pip install --no-cache-dir huffman \
  && make -C mpy-cross

WORKDIR "/circuitpython/ports/${PORT}"

RUN make fetch-port-submodules

RUN \
  esp-idf/install.sh \
  && . esp-idf/export.sh \
  && pip install --no-cache-dir -r ../../requirements-dev.txt -r ../../requirements-doc.txt \
  && esp-idf/tools/idf_tools.py install

RUN  \
  . esp-idf/export.sh \
  && make BOARD="${BOARD}"

WORKDIR /
RUN \
  mkdir -v /firmware \
  && cp -v /circuitpython/ports/${PORT}/build-${BOARD}/firmware.bin /firmware/firmware.bin \
  && cp -v /circuitpython/ports/${PORT}/build-${BOARD}/circuitpython-firmware.bin /firmware/circuitpython-firmware.bin

CMD ["/bin/bash"]
