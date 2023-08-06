docker build --progress plain . -f Dockerfile-centos --target php-base || exit 1
docker build --progress plain . -f Dockerfile-centos --target with-node || exit 1
docker build --progress plain . -f Dockerfile-centos --target with-gcloud || exit 1
echo "Success"
