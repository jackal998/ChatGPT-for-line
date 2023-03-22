```
FROM google/cloud-sdk:alpine as builder1

RUN gcloud components install docker-credential-gcr --quiet
RUN docker-credential-gcr version


FROM docker/compose

COPY --from=builder1 /google-cloud-sdk/bin/* /usr/local/bin/
RUN docker-credential-gcr configure-docker
CMD docker-compose
```
