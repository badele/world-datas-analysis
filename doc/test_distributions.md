# Test project on various distributions

```bash
#!/usr/bin/env bash

DISTROS=(
	"alpine/edge"
	"archlinux/current"
	"ubuntu/noble"
)

cleanup() {
	incus delete wda-test -f >/dev/null 2>&1 || true

	exit 0
}
trap cleanup EXIT HUP INT TERM

for DISTRO in "${DISTROS[@]}"; do
	echo "Creating VM for $DISTRO..."

	incus delete wda-test -f >/dev/null 2>&1 || true

	incus create "images:$DISTRO" wda-test --vm --device root,size=20GiB -c security.secureboot=false
	incus config device add wda-test project disk "source=$PWD" path=/project shift=true
	incus start wda-test

	# Wait the instance has started
	while ! incus exec wda-test -- ls -alh >/dev/null 2>&1; do
		echo "Waiting for the instance to be ready..."
		sleep 1
	done

	incus exec wda-test -- /project/install_requirements.sh
	incus exec wda-test -- bash -c "cd /project ; just docker-build"
	incus exec wda-test -- bash -c "cd /project ; just import"
done
```
