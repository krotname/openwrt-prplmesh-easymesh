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
- One controller-to-near-agent wired path measured 904.32 Mbit/s in one
  direction and 893.84 Mbit/s in the other.
- At the earlier historical checkpoint, a hardware reboot changed the boot identity. Normal and recovery management
  returned in about 19 seconds, both agents were active with Ethernet backhaul
  in about 35 seconds, required ports remained in the main bridge at 1000/full,
  and post-reboot live acceptance passed 19/19.
- At the final controller-restart checkpoint, both agents again returned
  Active/Ethernet behind one occupied controller-side uplink at 1000/full. An
  unused port remained in the main bridge with no carrier, required LAN
  services stayed reachable, and LiveSafe r8 passed 19/19 with no skips.

Human verification needed: reproduce the topology and per-band read-back after
a clean reboot, preserve a sanitized transcript, and do not mix the historical
hardware-reboot and later controller-restart checkpoints. Do not generalize
the first-path throughput or occupied-uplink result to the second cascaded path.

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
- per-band SSID validation rejects substring and duplicate-name false positives;
- r8 restores the OpenWrt hostapd control-client socket permission patch that
  the reproducible r6 recipe omitted.

Human verification needed: run the unit and fixture tests from a clean checkout
and report the exact current totals, not remembered totals.

### F. Wireless capability boundary

- 802.11r was disabled on the OpenWrt access point at the checkpoint.
- A compatible cross-vendor mobility domain and FT security profile were not
  demonstrated.
- Mesh-wide MLO is impossible on the unchanged hardware because the OpenWrt
  access point and Wi-Fi 6 agent do not provide EHT/MLO.
- The observed OpenWrt client association used WPA2-Personal with PSK-SHA256
  and 802.11ax, while the farther agent's 6 GHz radio reported WPA3-SAE and
  320 MHz.
- A common SSID therefore does not prove a common security, FT, or MLO profile;
  6 GHz roaming and MLO were not demonstrated.
- The agent does not expose a 6 GHz radio identifier to the controller. A
  separate fail-closed compensating guard was live-verified with exact hardware
  identity, dynamic DHCP discovery, an off-device backup gate, one allowlisted
  combined write, and `NOOP` checks at 12, 60, and 180 seconds.
- At the final controller session, the one permitted combined write restored
  the exact expected SSID, WPA3-SAE, and 320 MHz profile before the 12/60/180
  checks each returned `NOOP`. The guard is not a prplMesh core feature.

Human verification needed: retain this hardware and profile boundary unless a
new configuration and direct client telemetry prove a narrower claim.

### G. r8 source-fix boundary

- r6 was reproducible but failed at runtime because its wireless control
  library used pristine upstream hostapd control-client sources without
  OpenWrt's socket permission patch.
- r8 pins and verifies the upstream source, applies the official OpenWrt
  `610-hostapd_cli_ujail_permission.patch`, and verifies the patched source.
- The source compatibility suite passed 9/9 and the APK artifact suite passed
  11/11; the package contained no replacement system Wi-Fi daemon.
- r8 was installed and survived a hardware reboot. The changed boot identity,
  return of both management paths, two active Ethernet agents, bridge and link
  state, and post-reboot acceptance 19/19 were all checked directly.

Human verification needed: distinguish the diagnosed r6 failure, the r8 source
fix, the verified single hardware reboot, and still-unproven failure scenarios.

### H. Explicit limitations

- no Wi-Fi Alliance certification claim;
- no verified cross-vendor 802.11r claim;
- no mesh-wide MLO claim on unchanged hardware;
- no claim of zero-loss or imperceptible roaming;
- no per-link gigabit claim for the full cascade;
- no physical-device restore claim;
- no claim that the vendor-local 6 GHz guard is a prplMesh core feature;
- no claim that one successful r8 reboot covers every power, reset, cable, or
  upgrade sequence;
- the second wired-path throughput test was not run;
- the physical walking-roam test was skipped and not run;
- physical restore and 802.11r/FT validation remain pending, while mesh-wide
  MLO remains unsupported on the unchanged hardware.

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
