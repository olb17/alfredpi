SHELL := /bin/bash

build_deploy:
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix phx.digest.clean --all
	cd ../alfredpi_ui; MIX_TARGET=alfredpi_rpi3a mix assets.deploy
	source ../../nerves_systems/o/alfredpi_rpi3a/nerves-env.sh ; MIX_TARGET=alfredpi_rpi3a mix firmware
	source ../../nerves_systems/o/alfredpi_rpi3a/nerves-env.sh ; MIX_TARGET=alfredpi_rpi3a ./upload.sh 192.168.100.115
