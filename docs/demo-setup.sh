#!/bin/sh
# Builds the throwaway project docs/demo.tape records against.
#
# It makes /tmp/runtest-demo holding a `Makefile` whose `test` target prints a
# believable three-suite run and exits 1, plus a stand-in `taskpolicy` that prints
# the policy it was handed and then execs the command. On macOS the real
# /usr/bin/taskpolicy does exactly that; the stand-in only exists because this
# recording is made on Linux. It also copies bin/runtest in, so `runtest` on PATH
# is this build and not some other install.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
demo=${1:-/tmp/runtest-demo}

rm -rf "$demo"
mkdir -p "$demo"
cp "$root/bin/runtest" "$demo/runtest"

cat > "$demo/taskpolicy" <<'STANDIN'
#!/bin/sh
printf '[taskpolicy] %s\n' "$1"
shift
exec "$@"
STANDIN
chmod +x "$demo/taskpolicy"

cat > "$demo/Makefile" <<'MAKEFILE'
test:
	@printf 'PASS  auth   1.20s\n'
	@sleep 1
	@printf 'PASS  cart   0.83s\n'
	@sleep 1
	@printf 'FAIL  feeds  expected 3, got 2\n'
	@exit 1
MAKEFILE

echo "demo project ready in $demo"
