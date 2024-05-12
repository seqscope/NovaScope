# Start from a base image with gcc and make installed
#FROM ubuntu:20.04
FROM snakemake/snakemake

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update && apt-get install -y \
    g++ \
    make \
    cmake \
    curl \
    git \
    xxd \
    unzip \
    zlib1g-dev \
    libbz2-dev \
    libdeflate-dev \
    liblzma-dev \
	libcurl4-openssl-dev \
	libgsl0-dev \
	libncurses5-dev \
	libperl-dev \
	libssl-dev \
    wget \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/lib/dpkg/* /var/cache/apt/* /var/log/apt

ENV HTSLIB_VERSION=1.20

# Download and install htslib
RUN wget https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2 \
    && tar -xjf htslib-${HTSLIB_VERSION}.tar.bz2 \
    && cd htslib-${HTSLIB_VERSION} \
    && ./configure \
    && make \
    && make install

# Download and install samtools
RUN wget https://github.com/samtools/samtools/releases/download/${HTSLIB_VERSION}/samtools-${HTSLIB_VERSION}.tar.bz2 \
    && tar -xjf samtools-${HTSLIB_VERSION}.tar.bz2 \
    && cd samtools-${HTSLIB_VERSION} \
    && ./configure \
    && make \
    && make install \
    && cd .. && 'rm' -rf samtools-${HTSLIB_VERSION} && 'rm' samtools-${HTSLIB_VERSION}.tar.bz2

ENV STAR_VERSION=2.7.11b
# Download and install STAR
RUN curl -k -L -o STAR-${STAR_VERSION}.zip https://github.com/alexdobin/STAR/archive/${STAR_VERSION}.zip \
    && unzip STAR-${STAR_VERSION}.zip \
    && cd STAR-${STAR_VERSION}/source \
    && make STARstatic \
    && cp STAR /usr/local/bin \
    && cd ../.. && 'rm' -rf STAR-${STAR_VERSION} && 'rm' STAR-${STAR_VERSION}.zip

# Install qgenlib
RUN git clone https://github.com/hyunminkang/qgenlib.git \
    && cd qgenlib && \
    && mkdir build && \
    && cd build && \
    && cmake .. && \
    && make

# Install spatula
RUN git clone -b dev https://github.com/seqscope/spatula.git
RUN cd spatula \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make \
    && cp /app/spatula/bin/spatula /usr/local/bin

# Install novascope/ficture
RUN git clone -b cli https://github.com/seqscope/novascope.git \
    && cd novascope \
    && pip install numpy pandas Pillow PyYAML pyarrow \
    && cd submodules \
    && rm -rf ficture \
    && git clone -b stable https://github.com/seqscope/ficture.git \
    && pip install -r ficture/requirements.txt

# Command to run when starting the container
COPY ./entrypoint.sh /
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
