#!/usr/bin/env bash
# Runs every scripts/test_*.gd headless and compares with the recorded baseline.
#   scripts/qa/run_all_tests.sh [godot_binary]
# Exit code 1 only for an UNEXPECTED failure. KNOWN_FAIL are pre-existing integrated1 failures
# recorded in documentation/MERGE_LOG.md (Phase 0); they are not merge regressions and are not fixed here.
GODOT="${1:-godot}"
KNOWN_FAIL=" test_interaction_stability test_mars_photorealistic_simulator test_photorealistic_moon_simulator test_polish_and_fixes "
cd "$(dirname "$0")/../.." || exit 2
"$GODOT" --headless --path . --import >/dev/null 2>&1
bad=0
for t in scripts/test_*.gd; do
	n=$(basename "$t" .gd)
	timeout 300 "$GODOT" --headless --path . --script "res://$t" >"/tmp/$n.log" 2>&1
	rc=$?
	if [ $rc -eq 0 ]; then status="PASS"
	elif [[ "$KNOWN_FAIL" == *" $n "* ]]; then status="known-fail"
	else status="FAIL"; bad=1; fi
	printf '%-45s %s\n' "$n" "$status"
done
exit $bad
