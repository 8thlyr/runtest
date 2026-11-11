# Rendered to docs/demo.gif by `vhs docs/demo.tape` from the repo root, after
# `make build && sh docs/demo-setup.sh`.
#
# Recorded on Linux. RunTest's Auto mode is macOS-only, so the demo project carries a
# stand-in `taskpolicy` that prints the policy it was handed and then execs the command.
# macOS's real /usr/bin/taskpolicy does the same thing, so the run looks the same.
Output docs/demo.gif
Set Shell "bash"
Set FontSize 15
Set Width 1000
Set Height 620
Set Padding 14
Set TypingSpeed 30ms

Hide
Type "cd /tmp/runtest-demo && export PATH=/tmp/runtest-demo:$PATH"
Enter
Sleep 600ms
Show

Type "# the agent's test command today, at full priority:"
Enter
Sleep 400ms
Type "make test"
Enter
Sleep 3400ms

Type "# the same command, wrapped once:"
Enter
Sleep 400ms
Type "runtest mode auto"
Enter
Sleep 800ms
Type "runtest make test"
Enter
Sleep 3600ms

Type "# arguments pass through untouched, and so does the exit code:"
Enter
Sleep 400ms
Type "runtest make test; echo exit code: $?"
Enter
Sleep 3600ms

Type "runtest status --json"
Enter
Sleep 1500ms

Type "runtest mode local && echo 'back to normal priority'"
Enter
Sleep 1200ms
