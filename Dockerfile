#### BUILD ENV ####
FROM python:3.9.10-slim-bullseye AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'Acquire::Check-Valid-Until "false";\n\
Acquire::Check-Date "false";' > /etc/apt/apt.conf.d/10no--check-valid-until && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        build-essential \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python3 -m venv $VIRTUAL_ENV && \
    pip3 install --no-cache-dir --upgrade pip==22.0.4

# Install dependencies
COPY service/requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt


#### PRODCUTION ENV ####
FROM python:3.9.10-slim-bullseye AS production

ENV DEBIAN_FRONTEND=noninteractive
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN apt-get update && apt-get upgrade -y
COPY --from=build /opt/venv /opt/venv

# Copy code
COPY service /service/
WORKDIR /service
USER nobody:nogroup

ARG VERSION
ENV VERSION=${VERSION}

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0"]

