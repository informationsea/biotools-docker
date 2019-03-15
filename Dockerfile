FROM alpine AS build-base
RUN apk add gcc g++ gfortran make automake autoconf libtool cmake zlib zlib-dev bzip2 bzip2-dev ncurses ncurses-dev xz xz-dev readline readline-dev curl curl-dev wget freetype-dev freetype libjpeg-turbo-dev libxml2-dev

FROM build-base AS samtools-build
RUN mkdir -p /build
WORKDIR /build
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2
RUN tar xjf samtools-1.9.tar.bz2
WORKDIR /build/samtools-1.9
RUN ./configure --prefix=/usr && make -j4 && make install DESTDIR=/dest

FROM build-base AS bcftools-build
RUN mkdir -p /build
WORKDIR /build
RUN curl -OL https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2
RUN tar xjf bcftools-1.9.tar.bz2
WORKDIR /build/bcftools-1.9
RUN ./configure --prefix=/usr && make -j4 && make install DESTDIR=/dest

FROM build-base AS bwa-build
RUN mkdir -p /build
WORKDIR /build
RUN curl -OL https://downloads.sourceforge.net/project/bio-bwa/bwa-0.7.17.tar.bz2
RUN tar xjf bwa-0.7.17.tar.bz2
WORKDIR /build/bwa-0.7.17
RUN make -j4
RUN mkdir -p /dest/usr/bin /dest/usr/share/man/man1
RUN cp bwa /dest/usr/bin && cp bwa.1 /dest/usr/share/man/man1

FROM build-base AS fastqc-install
RUN curl -OL https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip
RUN unzip fastqc_v0.11.8.zip
WORKDIR /FastQC
RUN chmod +x fastqc

FROM build-base AS msisensor-build
RUN curl -OL https://github.com/ding-lab/msisensor/archive/0.5.zip
RUN unzip 0.5.zip
WORKDIR /msisensor-0.5
RUN sed -ie 's/-ltinfo//g' vendor/samtools-0.1.19/Makefile
RUN make

FROM build-base AS snpeff-install
RUN apk add openjdk8
RUN curl -OL https://downloads.sourceforge.net/project/snpeff/snpEff_latest_core.zip
RUN unzip snpEff_latest_core.zip
RUN java -jar /snpEff/snpEff.jar download hg19

FROM build-base AS hisat2-install
RUN curl -OL http://ccb.jhu.edu/software/hisat2/dl/hisat2-2.1.0-Linux_x86_64.zip
RUN unzip hisat2-2.1.0-Linux_x86_64.zip

FROM build-base AS stringtie-install
RUN curl -OL http://ccb.jhu.edu/software/stringtie/dl/stringtie-1.3.5.tar.gz
RUN tar xzf stringtie-1.3.5.tar.gz
WORKDIR /stringtie-1.3.5
RUN sed -ie '1i #include <stdint.h>' gclib/GThreads.h
RUN make

FROM build-base AS bowtie2-install
RUN curl -OL https://downloads.sourceforge.net/project/bowtie-bio/bowtie2/2.3.4.3/bowtie2-2.3.4.3-linux-x86_64.zip
RUN unzip bowtie2-2.3.4.3-linux-x86_64.zip

FROM build-base AS python3-bio
RUN apk add python3 python3-dev openblas openblas-dev
RUN pip3 install virtualenv vcfpy cython numpy scipy matplotlib networkx cyvcf2 jinja2 pyfaidx pygments pyliftover pysam pyyaml rtree yapf ipython biopython jsonschema pyfaidx pyfasta flask openpyxl pyexcel pyvcf
RUN pip3 install pandas seaborn cnvkit multiqc

FROM build-base AS R-bio
RUN apk add openjdk8
RUN apk add R R-dev
ADD install.R /
RUN Rscript /install.R

FROM build-base AS gatk-install
RUN curl -OL https://github.com/broadinstitute/gatk/releases/download/4.1.0.0/gatk-4.1.0.0.zip
RUN unzip gatk-4.1.0.0.zip

FROM build-base AS rsem-build
RUN curl -OL https://github.com/deweylab/RSEM/archive/v1.3.1.tar.gz
RUN tar xzf v1.3.1.tar.gz
WORKDIR /RSEM-v1.3.1

FROM informationsea/biobuild
RUN apk add emacs vim man man-pages python3 python3-dev R R-dev openjdk8 zsh font-noto coreutils font-noto-gothic gdb clang bash-completion bash fontconfig-dev
COPY --from=samtools-build /dest /
COPY --from=bcftools-build /dest /
COPY --from=bwa-build /dest /
COPY --from=msisensor-build /msisensor-0.5/msisensor /usr/bin
COPY --from=fastqc-install /FastQC /opt/FastQC
RUN ln -s /opt/FastQC/fastqc /usr/bin
COPY --from=snpeff-install /snpEff /opt/snpEff
COPY --from=hisat2-install /hisat2-2.1.0 /opt/hisat2-2.1.0
RUN ln -s /opt/hisat2-2.1.0/hisat2 /usr/bin && ln -s /opt/hisat2-2.1.0/hisat2-build /usr/bin
COPY --from=stringtie-install /stringtie-1.3.5 /opt/stringtie-1.3.5
RUN ln -s /opt/stringtie-1.3.5/stringtie /usr/bin
COPY --from=bowtie2-install /bowtie2-2.3.4.3-linux-x86_64 /opt/bowtie2-2.3.4.3-linux-x86_64
RUN ln -s /opt/bowtie2-2.3.4.3-linux-x86_64/bowtie2 /opt/bowtie2-2.3.4.3-linux-x86_64/bowtie2-build /usr/bin
COPY root /
ENTRYPOINT [ "/entry.sh" ]