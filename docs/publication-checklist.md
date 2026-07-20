# Publication checklist

Use this checklist before copying any part of the evidence pack into a public
repository, blog, issue, merge request, or community post.

## 1. Choose an allowed destination

- [ ] Re-read the destination's current contribution and AI-content policy.
- [ ] For the OpenWrt Forum, read the
      [current guidelines](https://forum.openwrt.org/guidelines).
- [ ] Do not submit this AI-assisted text unchanged to the OpenWrt Forum.
- [ ] If posting there at all, write the text independently from tests you
      personally reproduced and evidence you personally checked.
- [ ] For code or packaging changes, prefer the relevant upstream issue or
      merge-request workflow when it permits the proposed contribution.

## 2. Export by allowlist

- [ ] Start from a new, empty export directory.
- [ ] Copy only reviewed public Markdown, source, tests, and patches.
- [ ] Do not copy a complete working directory and then try to remove secrets.
- [ ] Exclude private documentation, raw configuration, backups, restore
      archives, logs, crash dumps, packet captures, firmware, package artifacts,
      browser data, and proprietary web resources.
- [ ] Exclude photographs or screenshots unless metadata and every device label
      have been reviewed and redacted.

## 3. Remove deployment identity

- [ ] Replace every real SSID with `<MESH_SSID>`.
- [ ] Replace every secret with `${MESH_PSK}` or another explicit placeholder.
- [ ] Replace real IP addresses with RFC 5737 documentation addresses.
- [ ] Replace real MAC addresses with locally administered examples beginning
      with `02:`.
- [ ] Remove hostnames, usernames, serial numbers, PINs, QR codes, tokens,
      cookies, session identifiers, lease names, and device-label data.
- [ ] Remove absolute local and remote filesystem paths.
- [ ] Inspect image metadata and repository history, not only current text.

## 4. Run privacy and secret scans

- [ ] Scan the exact export tree with a maintained secret scanner.
- [ ] Search for high-entropy strings and encoded credentials.
- [ ] Search for private-address literals, hardware-address patterns, and
      absolute filesystem paths.
- [ ] Review every match manually; a clean exit code is not sufficient.
- [ ] Confirm that the only example IPv4 addresses are in documentation ranges.
- [ ] Confirm that every example MAC address is locally administered.
- [ ] Review the final archive or commit from a clean checkout.

## 5. Keep claims within evidence

- [ ] Distinguish observed state from inferred capability.
- [ ] State which link, not merely which topology, was measured at 1 Gbit/s.
- [ ] Do not claim 802.11r, MLO, lossless roaming, certification, or universal
      vendor interoperability without direct evidence.
- [ ] Describe isolated archive extraction as an isolated restore test, not a
      physical-device restore.
- [ ] Mark the clean SDK build as blocked until all feeds and dependencies are
      available and a fresh build completes.
- [ ] Separate non-disruptive automated checks from manual disruptive tests.
- [ ] Include evidence date, software versions, and the exact test scope.

## 6. Make the build reproducible

- [ ] Replace local source-directory overrides with an upstream URL and an
      immutable commit or release reference.
- [ ] Publish a minimal, reviewable patch series rather than a modified source
      tree with unknown provenance.
- [ ] Record toolchain and feed revisions needed for the build.
- [ ] Build from a clean environment and retain the build log privately.
- [ ] Re-run unit, target-syntax, packaging, and non-disruptive live acceptance
      tests against the candidate publication commit.

## 7. Preserve licensing and attribution

- [ ] Retain upstream license, license-directory, authorship, copyright, and
      SPDX files.
- [ ] Audit mixed-license subtrees instead of declaring only the top-level
      project license.
- [ ] Confirm that every proposed file can legally be redistributed.
- [ ] Do not redistribute proprietary firmware, web UI assets, or extracted
      vendor code.
- [ ] Follow the upstream DCO, `Signed-off-by`, authorship, issue, and source
      header rules.

## 8. Final human review

- [ ] A human has reproduced the commands or tests being described.
- [ ] A human has reviewed every line of the exact outgoing content.
- [ ] Links point to official projects or documentation, not private systems.
- [ ] No external publication is claimed until the destination displays the
      submitted content or accepted change.
