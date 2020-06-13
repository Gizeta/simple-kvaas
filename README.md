# simple-kvaas
Simple KVaaS for personal use.

## build image
```bash
docker build -t simple_kvaas:nightly .
```

## run image
```bash
docker run --publish 8080:8080 -it simple_kvaas:nightly
```

## publish image
```bash
docker push {username}/simple_kvaas:nightly
```
