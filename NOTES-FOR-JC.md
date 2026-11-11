# Notes for JC: runtest

- **It clears the ship bar on its own terms now.** README has Why / Quickstart / How it works, `docs/demo.gif` is a real recording (`vhs docs/demo.tape`), and there's a `v0.1.0` release with the compiled binary attached. The demo shows the shape that matters: `make test` fails, then `runtest make test` produces identical output with `[taskpolicy] -b` in front and the same exit code, so an agent's loop can't tell the difference.
- **The demo is honest about being recorded on Linux.** Auto is macOS-only, so `docs/demo-setup.sh` puts a stand-in `taskpolicy` on PATH that prints the policy and execs the command, and the tape says so in a comment. The alternative was faking macOS output, which would read as slop to anyone who knows `taskpolicy`.
- **Two real bugs the Linux run caught.** `mkstemp` was implicitly declared under `-std=c17 -Werror` (the build was macOS-only by luck), and `executable_is_on_path` sized its buffer one byte short of the separator, so a `PATH` entry that was exactly the command's length would have truncated. Both fixed, plus the status test now asks `shutil.which("taskpolicy")` instead of assuming macOS.

**Visibility:** `8thlyr/runtest` is **public**, one of the three Studio repos that stayed public after 11/10. This PR is a normal push to main.
