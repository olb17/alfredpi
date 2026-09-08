SHELL := /bin/bash
DEVICE_ADDR := 192.168.100.115

build_deploy:
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix phx.digest.clean --all
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix assets.deploy
	MIX_TARGET=alfredpi_rpi3a mix firmware
	MIX_TARGET=alfredpi_rpi3a ./upload.sh $(DEVICE_ADDR)

build_deploy_with_local_system:
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix phx.digest.clean --all
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix assets.deploy
	source ../../nerves_systems.old/o/alfredpi_rpi3a/nerves-env.sh ; MIX_TARGET=alfredpi_rpi3a mix firmware
	source ../../nerves_systems.old/o/alfredpi_rpi3a/nerves-env.sh ; MIX_TARGET=alfredpi_rpi3a ./upload.sh $(DEVICE_ADDR)

