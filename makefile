DOCKER_REGISTRY := mathematiguy
IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(DOCKER_ARGS) --runtime=nvidia --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
.PHONY: jupyter
jupyter: UID=root
jupyter: GID=root
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) bash -c 'jupyter lab \
		--allow-root \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.iopub_msg_rate_limit=1000000 \
		--NotebookApp.password=$(shell $(RUN) \
			python -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))"\
			)'

TENSORBOARD_DIR ?= notebooks/logdir
tensorboard: DOCKER_ARGS=-p 6006:6006
tensorboard:
	$(RUN) tensorboard --logdir $(TENSORBOARD_DIR)

notebooks/strokes-dataset: UID=root
notebooks/strokes-dataset: GID=root
notebooks/strokes-dataset:
	$(RUN) bash -c '(cd notebooks && \
		kaggle datasets download reiinakano/mypaint_brushstrokes --force) &&
		unzip mypaint_brushstrokes.zip'

notebooks/celeba-dataset: UID=root
notebooks/celeba-dataset: GID=root
notebooks/celeba-dataset:
	$(RUN) bash -c '(cd notebooks && \
		kaggle datasets download jessicali9530/celeba-dataset --force && \
		unzip celeba-dataset.zip)'


dependencies/libmypaint: dependencies/libmypaint-1.3.0.tar.xz
	(cd $(dir $@) && tar -xvf $(notdir $<) && mv libmypaint-1.3.0 libmypaint)

dependencies/libmypaint-1.3.0.tar.xz:
	wget https://github.com/mypaint/libmypaint/releases/download/v1.3.0/libmypaint-1.3.0.tar.xz -P $(dir $@)

dependencies/mypaint-1.2.1.tar.xz:
	wget https://github.com/mypaint/mypaint/releases/download/v1.2.1/mypaint-1.2.1.tar.xz -P $(dir $@)

dependencies/mypaint: dependencies/mypaint-1.2.1.tar.xz
	(cd $(dir $@) && tar -xvf mypaint-1.2.1.tar.xz && mv mypaint-1.2.1 mypaint)

dependencies/ngrok:
	(cd $(dir $@) && \
	 wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && \
	 unzip $(notdir $@))

clean:
	rm -rf dependencies/*

.PHONY: docker
docker: dependencies/libmypaint dependencies/mypaint dependencies/ngrok
	docker build --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: docker-push
docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

.PHONY: docker-pull
docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: enter
enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

.PHONY: enter-root
enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash

.PHONY: inspect-variables
inspect-variables:
	@echo DOCKER_REGISTRY: $(DOCKER_REGISTRY)
	@echo IMAGE_NAME:      $(IMAGE_NAME)
	@echo IMAGE:           $(IMAGE)
	@echo RUN:             $(RUN)
	@echo UID:             $(UID)
	@echo GID:             $(GID)
	@echo DOCKER_ARGS:     $(DOCKER_ARGS)
	@echo GIT_TAG:         $(GIT_TAG)
