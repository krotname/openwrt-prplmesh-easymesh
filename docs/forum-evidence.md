# OpenWrt Forum evidence note — not post-ready

> **Do not paste this file, or the accompanying article, into the OpenWrt
> Forum.** It is an AI-assisted evidence pack, not a forum submission.

## Why this distinction matters

At the evidence checkpoint, the
[OpenWrt Forum guidelines](https://forum.openwrt.org/guidelines) included the
instruction “Refrain From Posting Generative AI Content” and stated that
AI-generated technical tutorials or summaries are removed. The guideline
allows a narrower use for translation or editing of material authored by the
user.

Policies can change. Re-read the live guideline immediately before posting.
The safe interpretation for this project is:

1. do not submit this draft unchanged;
2. personally reproduce and understand the relevant tests;
3. select only facts you can independently support;
4. write a new post in your own words;
5. use AI, if permitted at that time, only within the narrow scope stated by
   the current guideline.

This file is not a workaround for the policy.

## Evidence cards for a human author

These cards are prompts for checking facts, not prose to copy.

### A. Architecture

- OpenWrt remained the router, DHCP server, default gateway, and one access
  point.
- prplMesh 6.0.1 provided the mesh controller function.
- Two proprietary EasyMesh agents used Ethernet backhaul in a cascade.
- The farther agent included a 6 GHz Wi-Fi 7 radio.
- A complete prplOS, WHM, or Ambiorix platform was not installed.

Human verification needed: record the current OpenWrt release, package version,
bridge membership, and a fresh topology snapshot.

### B. Interoperability result

- The controller reported two distinct active agents.
- Both agents reported Ethernet, not wireless, backhaul.
- Exact SSID checks passed for the intended 2.4, 5, and 6 GHz radio roles.
- The tested 6 GHz radio reported WPA3-SAE and 320 MHz operation.

Human verification needed: reproduce the topology and per-band read-back after
a clean reboot, then preserve a sanitized transcript.

### C. LAN safety lesson

- The backhaul Ethernet port also carried ordinary LAN services.
- Moving the entire physical port into a temporary mesh-only bridge disconnected
  those services.
- Keeping the port in the main LAN bridge allowed a narrow mesh test without
  that collateral outage.

Human verification needed: describe only the generic failure mode; do not
publish endpoint identities, leases, addresses, or private topology labels.

### D. Backup lesson

- Archive download, hashing, member enumeration, and isolated extraction were
  tested.
- Strict ownership validation found metadata defects that content-only checks
  would have missed.
- No destructive restore onto physical router hardware is claimed.

Human verification needed: rerun the current backup verifier and distinguish
archive extraction from hardware recovery.

### E. Software defects covered by regression tests

- ambiguous access-point fallback now fails closed;
- stale logs are removed before isolated stack probes;
- stack health requires the controller, transport, and agent components;
- MAC parsing rejects trailing garbage;
- management reads do not print a session token and perform best-effort logout;
- per-band SSID validation rejects substring and duplicate-name false positives.

Human verification needed: run the unit and fixture tests from a clean checkout
and report the exact current totals, not remembered totals.

### F. Explicit limitations

- no Wi-Fi Alliance certification claim;
- no verified 802.11r claim;
- no verified MLO claim;
- no claim of zero-loss or imperceptible roaming;
- no per-link gigabit claim for the full cascade;
- no physical-device restore claim;
- no successful clean SDK rebuild claim while required feed packages are
  unavailable.

Human verification needed: retain these limitations unless new direct evidence
closes each gap.

## Questions a human-written post could answer

- Which minimum controller and transport components were required on OpenWrt?
- What controller evidence distinguished Ethernet backhaul from a wireless
  repeater path?
- Which settings remained vendor-managed on the 6 GHz agent?
- How was the shared LAN bridge protected during onboarding and rollback?
- Which automated checks prevented an apparently healthy but partial stack from
  passing?
- What remains to be measured in a walking roam test?
- What is required to turn the local package build into a reproducible upstream
  recipe?

Writing answers from personal test notes produces a more useful and policy-safe
post than paraphrasing this file.

## Other publication paths

If a destination permits AI-assisted technical drafts, a sanitized repository
or personal technical article may be suitable after completing the
[publication checklist](publication-checklist.md). Code or packaging changes
intended for upstream should follow the
[prplMesh GitLab project](https://gitlab.com/prpl-foundation/prplmesh/prplMesh)
contribution process.

No external publication or upstream submission has been made by preparing this
evidence pack.
