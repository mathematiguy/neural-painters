FROM tensorflow/tensorflow:latest-gpu-jupyter

# Install dependencies for generate_stroke_examples
RUN apt-get update
RUN apt-get install -y libjson-c-dev libgirepository1.0-dev libglib2.0-dev
RUN apt-get install -y autotools-dev intltool gettext libtool
RUN apt-get install -y swig python-setuptools g++
RUN apt-get install -y libgtk-3-dev python-gi-dev
RUN apt-get install -y libpng-dev liblcms2-dev libjson-c-dev
RUN apt-get install -y gir1.2-gtk-3.0 python-gi-cairo
RUN apt-get install -y scons
RUN apt-get install -y ffmpeg

COPY requirements.txt /root/requirements.txt
RUN pip install -r /root/requirements.txt

COPY dependencies/libmypaint /root/libmypaint
RUN cd /root/libmypaint && ./configure && make install

COPY dependencies/mypaint /root/mypaint
RUN cd /root/mypaint && scons && scons install

COPY dependencies/kaggle.json /root/.kaggle/kaggle.json
