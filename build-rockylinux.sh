# alternatively:
# OS=rockylinux-9 PHP_VERSION=${PHP_VERSION-8.3} NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION-20} ./cloud-build-local.sh

build_arg="--build-arg PHP_VERSION=${PHP_VERSION-8.3} --build-arg NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION-20}"
docker build --progress plain . -f Dockerfile-rockylinux-9 --target php-base $build_arg || exit 1
docker build --progress plain . -f Dockerfile-rockylinux-9 --target with-node $build_arg || exit 1
docker build --progress plain . -f Dockerfile-rockylinux-9 --target with-gcloud $build_arg || exit 1
echo "Success"
