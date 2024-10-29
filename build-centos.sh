# alternatively:
# OS=centos-9 PHP=${PHP_VERSION-8.3} NODE=${NODE_MAJOR_VERSION-20} ./cloud-build-local.sh

build_arg="--build-arg PHP_VERSION=${PHP_VERSION-8.3} --build-arg NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION-22}"
docker build --progress plain . -f Dockerfile-centos-9 --target php-base $build_arg || exit 1
docker build --progress plain . -f Dockerfile-centos-9 --target with-node $build_arg || exit 1
docker build --progress plain . -f Dockerfile-centos-9 --target with-gcloud $build_arg || exit 1
echo "Success"
