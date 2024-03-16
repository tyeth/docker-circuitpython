FROM ubuntu:24.04

ARG CIRCUITPYTHON_VERSION="9.0.0-rc.1"
ARG PORT="atmel-samd"
ARG BOARD="pyportal_titano"

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y \
  && apt-get install -y wget tree

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
  ../espressif/esp-idf/install.sh \
  && . ../espressif/esp-idf/export.sh \
  && pip install --no-cache-dir -r ../../requirements-dev.txt -r ../../requirements-doc.txt \
  && ../espressif/esp-idf/tools/idf_tools.py install

RUN  \
  . ../espressif/esp-idf/export.sh \
  && make BOARD="${BOARD}"

WORKDIR /
RUN \
  mkdir -v /firmware \
  && tree /circuitpython/ports/${PORT}/build-${BOARD}/ \
  && cp -v /circuitpython/ports/${PORT}/build-${BOARD}/firmware.bin /firmware/firmware.bin \
  && cp -v /circuitpython/ports/${PORT}/build-${BOARD}/circuitpython-firmware.bin /firmware/circuitpython-firmware.bin \
  && cp -v /circuitpython/ports/${PORT}/build-${BOARD}/*.uf2 /firmware/circuitpython-firmware.uf2

CMD ["/bin/bash"]
