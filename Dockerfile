FROM python:3.11
WORKDIR /app
COPY . /app
RUN apt-get -qq update && apt-get -qq install -y git wget ffmpeg mediainfo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir -r requirements.txt
#original
#CMD ["python", "main.py"]
CMD flask run -h 0.0.0.0 -p 8080 & python3 main.py
