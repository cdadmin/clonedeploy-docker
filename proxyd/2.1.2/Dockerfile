FROM ubuntu:xenial

LABEL maintainer "cdadmin@clonedeploy.org"

ENV DEBIAN_FRONTEND=noninteractive \
	PROXY_VERSION=2.1.2 \
	RUN_TYPE="daemon" \
	LISTEN_DHCP=true \
	LISTEN_PROXY=true \
	LISTEN_APPLE_BSDP=true \
	INTERFACE=0.0.0.0 \
	NEXT_SERVER= \
	CLONEDEPLOY_BASE_URL=http://192.168.56.100/clonedeploy/ \
	CHECK_WEB_RESERVATIONS=true \
	CHECK_TFTP_CLUSTER=true \
	TFTP_POLLING_INTERVAL=30 \
	BIOS_BOOTFILE=proxy/bios/pxeboot.0 \
	EFI32_BOOTFILE=proxy/efi32/pxeboot.0 \
	EFI64_BOOTFILE=proxy/efi64/pxeboot.0 \
	APPLE_EFI_BOOT_FILE=proxy/efi64/ipxe.efi \
	APPLE_BOOT_FILE=[nbi_id]/i386/booter \
	APPLE_ROOT_PATH=http://192.168.56.100/clonedeploy/public/macos_nbis/[nbi_id]/NetBoot.dmg \
	APPLE_VENDOR_SPECIFIC_INFORMATION= \
	SERVER_IDENTIFIER_OVERRIDE= 
	
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
	&& echo "deb http://download.mono-project.com/repo/debian xenial main" | tee /etc/apt/sources.list.d/mono-xamarin.list 

RUN apt-get update && apt-get install -y \
	mono-devel \
	unzip \
	wget \
	&& rm -rf /var/lib/apt/lists/*
	
RUN wget -P /tmp "https://sourceforge.net/projects/clonedeploy/files/CloneDeploy%20Proxy%20DHCP/cd_proxyd-${PROXY_VERSION}.zip" \
	&& unzip /tmp/cd_proxyd-${PROXY_VERSION}.zip -d /usr/src/ \
	&& rm /tmp/cd_proxyd-${PROXY_VERSION}.zip 	

RUN cp -R /usr/src/cd_proxyd /opt 
		
COPY docker-entrypoint.sh /entrypoint.sh 
ENTRYPOINT ["/bin/bash","/entrypoint.sh"]
CMD ["sh", "-c", "mono /opt/cd_proxyd/cd_proxyd.exe echo --${RUN_TYPE}"]
