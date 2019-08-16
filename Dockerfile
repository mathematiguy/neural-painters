FROM tensorflow/tensorflow:latest-gpu-py3-jupyter

RUN apt-get update

COPY requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt
