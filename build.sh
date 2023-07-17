#!/bin/bash

# exit when any command fails
set -e

colors=("blue" "red" "green")
template="template.html"
# prompt the user for the docker image name if not set
if [[ -z $DOCKER_IMAGE_NAME ]]; then
	read -p "Enter the docker image name: " DOCKER_IMAGE_NAME
fi
function build_apps() {
	alt=$1
	suffix="-alt"
	if [[ -z $alt ]]; then
		suffix=""
	elif [[ -n $2 ]]; then
		suffix=$2
	fi
	for i in "${!colors[@]}"; do
		appNum=$((i + 1))
		color=${colors[$i]}
		echo "Building app$appNum with color $color"
		export appNum color suffix alt
		cat $template | envsubst >"index.html"
		# set -x
		docker buildx build --platform linux/arm64,linux/amd64 -t "$DOCKER_IMAGE_NAME:app$appNum$suffix" --push .
		if [[ $appNum -eq 3 && -z $alt ]]; then
			docker buildx build --platform linux/arm64,linux/amd64 -t "$DOCKER_IMAGE_NAME:1.0.2" --push .
		fi
		# set +x
	done
	rm index.html
}
function build_single_app() {
	appNum=1
	color=red
	alt=""
	cat $template | envsubst >"index.html"
	docker buildx build --platform linux/arm64,linux/amd64 -t "$DOCKER_IMAGE_NAME:$VERSION" --push .
	rm index.html
}
# if --single is passed, build only the first app
if [[ $1 == "--single" ]]; then
	echo "Building only app1"
	build_single_app
	exit 0
fi
build_apps
build_apps " - Alt"
