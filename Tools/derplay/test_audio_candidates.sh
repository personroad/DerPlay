#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
sources=(DerPlay/Extensions/AudioSessionOwnershipPolicy.swift DerPlay/Extensions/AudioSessionSerialExecutor.swift DerPlay/Extensions/AudioSessionRoutePolicy.swift DerPlay/Extensions/AudioSessionRouteTransaction.swift DerPlay/Extensions/PictureInPictureLifecyclePolicy.swift DerPlay/Extensions/PictureInPictureAudioCoordinator.swift DerPlay/Extensions/PictureInPictureControllerBinding.swift DerPlay/Extensions/PictureInPictureAsyncAudioCoordinator.swift)
for test in AudioSessionOwnership AudioSessionSerial AudioSessionAsync AudioSessionReactivation AudioSessionOwnerBackend AudioSessionRoute AudioSessionRouteTransaction PictureInPictureLifecycle PictureInPictureAudioCoordinator PictureInPictureControllerBinding PictureInPictureAsyncAudio; do
  echo "--- $test ---"
  swiftc -swift-version 5 "${sources[@]}" "Tools/derplay/${test}Smoke.swift" -o "$tmp/smoke"
  "$tmp/smoke"
done
