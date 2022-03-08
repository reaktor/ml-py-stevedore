#FROM fedora:latest
FROM python:3.9.10-slim-bullseye AS build

RUN echo "Acquire::Check-Valid-Until \"false\";\nAcquire::Check-Date \"false\";" | cat > /etc/apt/apt.conf.d/10no--check-valid-until
RUN apt-get update
RUN apt-get install -yq --no-install-recommends build-essential
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Setup venv
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip3 install --no-cache-dir --upgrade pip==22.0.4

# Install dependencies
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt


FROM python:3.9.10-slim-bullseye AS production

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=build /opt/venv /opt/venv
# Copy code
RUN mkdir -p /srv
COPY *.py /srv
WORKDIR /srv
#COPY service /app/service
USER nobody:nogroup

ARG VERSION
ENV VERSION=${VERSION}

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0"]



#RUN mkdir -p /srv
#COPY . /srv
#WORKDIR /srv

#RUN dnf install -y python-pip \
#    && dnf clean all \
#    && pip install fastapi uvicorn scikit-learn numpy jsonschema

