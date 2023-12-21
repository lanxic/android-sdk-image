IMAGE_TAG := $(IMAGE_TAG)
IMAGE := lanxic/android-sdk-image

release: \
	tag_image \
	dockerhub_push \

tag_image: build
	docker tag $(IMAGE):latest $(IMAGE):$(IMAGE_TAG)

build:
	docker build -t $(IMAGE) .

run:
	docker run -it --rm $(IMAGE) /bin/bash

dockerhub_push:
	docker push $(IMAGE):latest \
	&& docker push "$(IMAGE):$(IMAGE_TAG)"

.PHONY: release tag_image build dockerhub_push