docker build -t ubaca .
docker run -v "$PWD/conf:/ansible/playbooks/:rw" --rm -ti ubaca