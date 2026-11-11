# RunTest

[![CI](https://github.com/8thlyr/runtest/actions/workflows/ci.yml/badge.svg)](https://github.com/8thlyr/runtest/actions/workflows/ci.yml)

Coding agents run `npm test` in a loop, and every run competes with your editor, browser and
calls for the CPU. Put `runtest` in front of the command and, in Auto mode, macOS runs it at
background priority (`taskpolicy -b`), so the tests still finish and your laptop stays usable.

![runtest running a failing test suite directly, then the same suite under Auto mode with [taskpolicy] -b in front, then the exit code and status output](docs/demo.gif)

```sh
runtest mode auto     # once per macOS account
runtest npm test      # what the agent runs
```

## Why

An agent that fixes a failing test runs the suite ten times before you look up. Each run is a
full-build burst at normal priority, so your editor stutters, the call drops and the fan spins
up, and the agent still waits the same wall-clock time for its answer. Three ways people
usually fix that, and why this one is the smallest:

- **Renice the agent.** `nice` only orders processes that are already runnable. It does not
  mark them as background work, so macOS still schedules the build's threads eagerly and the
  fan and thermal behavior don't change. `taskpolicy -b` tells the scheduler what the work
  actually is.
- **Move tests to another machine.** That is a real fix and it is what RunTest's Remote mode
  is meant to grow into (#5), but it needs a second machine, a sync story and a way to trust
  the result. It should not be the price of admission.
- **Ask the agent to be polite.** Agents forget. A wrapper the command line already contains
  does not.

RunTest is the seam between the agent and its test command: one ~300-line C program that
either executes the command or executes it under `taskpolicy -b`, and nothing else.

## Quickstart

You need macOS 13 or newer and a C compiler (the Xcode command line tools give you `cc`).

```sh
git clone https://github.com/8thlyr/runtest.git
cd runtest
make build
install bin/runtest /usr/local/bin/runtest

runtest status          # Local, no saved mode
runtest mode auto       # once per macOS account
runtest status          # Auto, saved
runtest npm test        # the agent's command, at background priority
```

Tell your agents to use it. Add this to `AGENTS.md` or `CLAUDE.md`:

```markdown
## Running tests
Prefix every test command with `runtest`, for example `runtest npm test` or
`runtest pytest -x`. It runs the command unchanged at background priority. Do not wrap it in
`sh -c` unless the command needs shell syntax.
```

## How it works

`runtest <command> [arguments ...]` reads one small mode file, then either `execvp`s the
command or `execvp`s `taskpolicy -b` with the command behind it. There is no supervisor
process, no log, no daemon and no shell: the exit code and signal you get back are the
command's own, because after the `exec` the process *is* the command.

1. **Argument handling is the point.** `argv[1]` selects a subcommand (`status`, `mode`) or is
   the command itself. Everything after it is passed through untouched, with no quoting,
   splitting or `sh -c`, so `runtest pytest -k "not slow"` and `runtest make build CFLAGS=-O0`
   reach the command the way you typed them. Shell syntax needs an explicit shell.
2. **The mode belongs to the account, not the caller.** The file is
   `~/Library/Application Support/RunTest/mode`, resolved from `getpwuid` rather than `$HOME`,
   so an agent cannot split the shared setting by exporting a different home directory. Writes
   go to a temporary file in the same directory and are `rename`d into place, so a reader
   never sees a half-written mode and two agents switching modes cannot interleave.
3. **The state is read once, before the command starts.** `runtest` reads the mode, then
   execs. Changing the mode afterwards affects the next invocation and never interrupts a
   running command, which is what makes `runtest mode local` a safe panic button.
4. **It never lies about what it did.** If `taskpolicy` is missing, Auto prints
   `Auto policy is unavailable; falling back to direct local execution` and runs the command
   anyway. `status` reports the same thing as `"available": false` with the fallback named, so
   a setup script can check rather than assume.

## Status

- Early stage. Only the Local and Auto modes exist today. Remote routing is planned (#5) and not built yet.
- The open GitHub issues describe the roadmap (as of 2026-10-20): shared test-command router (#1), Crabbox remote routing (#5), local timing evidence (#6), recommending remote suites (#7), guided Local/Auto and Remote setup (#8, #9), a native menu-bar app and project routing (#10, #11), SketchyBar controls (#12), diagnosing stuck installs (#13), Homebrew tap install and releases (#14, #15).
- macOS only for Auto (`taskpolicy`, Application Support path).
- CI builds and runs the test suite on a macOS runner.

## Stack

- C (`src/runtest.c`), built with `cc -std=c17 -Wall -Wextra -Wpedantic -Werror`.
- Python `unittest` test suite that runs the binary as an external process.
- Make.

## Build from source

```sh
make build
./bin/runtest npm test
./bin/runtest python3 -m unittest
```

With `bin` on `PATH`: `runtest <command> [arguments ...]`. Commands do not need to use npm. RunTest does not interpret shell syntax; call a shell explicitly when needed:

```sh
runtest sh -c 'printf "%s\n" "$HOME"'
```

`runtest` with no command prints usage and exits 64.

## Modes

```sh
runtest status
runtest status --json
runtest mode local
runtest mode auto
```

- `status --json` reports the mode, whether it came from saved state or the safe default, and whether Auto's background policy is available. Reading status does not create or change the state file.
- The mode is stored at `~/Library/Application Support/RunTest/mode`. An update writes a complete new file and atomically replaces the old one, so concurrent readers never see a partial value. A missing file means Local.
- RunTest asks macOS for the account's home folder instead of trusting `HOME`, so callers cannot split the shared mode by changing their environment.
- Auto runs `taskpolicy -b <command> [arguments ...]`. If `taskpolicy` is missing, status names the fallback as `direct local execution`, and Auto prints the same notice to stderr and runs the command directly. It never claims the background policy was applied.
- Each invocation reads the mode once before it starts the command; changing it affects later invocations only and never interrupts a running command.

## Tests

```sh
make test    # builds bin/runtest-test with -DRUNTEST_TESTING, runs the unittest suite in tests/
make check   # syntax-only compile of both builds + python3 -m compileall tests
```

The suite runs the real binary and asserts on its behavior rather than its source: pass-through
arguments, exit codes, signals and stdin, the atomic mode swap under concurrent writers, the
`taskpolicy` double, and the fallback notice when `taskpolicy` is missing from `PATH`. Nothing
in it touches your real mode file; the test build reads `RUNTEST_TEST_ACCOUNT_HOME` instead.

## Configuration

No configuration environment variables; commands are looked up on the caller's `PATH`. The test build alone reads `RUNTEST_TEST_ACCOUNT_HOME`, and `make test` passes the test binary to the suite as `RUNTEST_UNDER_TEST`.

## Layout

```text
src/runtest.c        the command seam
tests/               Python unittest suite (test_cli.py)
Makefile             build, test, check
AGENTS.md            agent guide
docs/demo.tape       vhs tape for docs/demo.gif
docs/demo-setup.sh   builds the throwaway project the tape records against
docs/agents/         domain.md, issue-tracker.md, triage-labels.md
```

## License

MIT. See [LICENSE](LICENSE).

## Links

- Issues: https://github.com/8thlyr/runtest/issues
- Related: [execution-target-switch](https://github.com/jonathancostin/execution-target-switch), a related project built around the same Local / low-impact / remote idea.
