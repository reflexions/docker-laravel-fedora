# alternatively:
# OS=centos-9 PHP=${PHP_VERSION-8.3} NODE=${NODE_MAJOR_VERSION-20} ./cloud-build-local.sh

build_arg="--build-arg PHP_VERSION=${PHP_VERSION-8.3} --build-arg NODE_MAJOR_VERSION=${NODE_MAJOR_VERSION-22}"

pids=()
centos_versions=( 8 9 10 )
for version in "${centos_versions[@]}"; do
	docker build --progress plain . -f Dockerfile-centos-${version} --target with-gcloud $build_arg &
	pids[${version}]=$!
done

# wait for all pids
failed=false
for pid in "${pids[@]}"; do
	wait $pid || { echo "$pid failed"; failed=true; }
done

if [ $failed ]; then
	echo "Failed"
	exit 1
else
	echo "Success"
fi
