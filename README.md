# Wired third-party EasyMesh agents with prplMesh on OpenWrt

**[Русская версия для Хабра](docs/habr-ru.md)** · **[Publication checklist](docs/publication-checklist.md)**

![Three access points connected by a cascaded wired backhaul while ordinary LAN services remain online](assets/hero-wired-easymesh.png)

Status: sanitized technical report, not a ready-to-post forum article
Evidence checkpoint: 2026-07-20

## Abstract

This experiment tested whether an OpenWrt router could remain the only router,
DHCP server, and default gateway while also running prplMesh 6.0.1 as the mesh
controller and a local access point. Two proprietary EasyMesh devices were
attached as agents over a cascaded Ethernet backhaul; the farther agent also
provided a 6 GHz Wi-Fi 7 radio.

At the recorded checkpoint, both agents appeared in the controller topology as
active Ethernet neighbors, the expected common SSID was visible on the tested
radios, and unrelated wired LAN services remained reachable. This is useful
interoperability evidence, but it is not certification and it does not imply
support for every EasyMesh feature.

## Scope and tested architecture

```text
                         routing, NAT, DHCP
Internet --------------- OpenWrt controller/AP
                              |
                         shared LAN bridge
                              |
                        Ethernet backhaul
                              |
                       EasyMesh agent A
                              |
                        Ethernet backhaul
                              |
                       EasyMesh agent B
                       (includes 6 GHz)
```

![Exact topology: OpenWrt controller, two cascaded Ethernet EasyMesh agents, and services sharing the LAN bridge](assets/topology.png)

*The critical boundary is the shared LAN bridge: isolate the mesh protocol path, not the whole physical downstream port.*

The OpenWrt installation retained its normal Linux bridge and UCI network
model. prplMesh was packaged locally for that environment; a complete prplOS,
WHM, or Ambiorix platform was not installed. The proprietary agents retained
their vendor firmware.

The interoperability boundary was therefore IEEE 1905.1/EasyMesh control
traffic plus Ethernet backhaul. Vendor-specific management remained outside
the controller where a standardized operation was unavailable.

## What was observed

| Area | Recorded evidence | Result |
|---|---|---|
| Controller | Controller and IEEE 1905 transport processes stayed running | Pass |
| Topology | Two distinct agents appeared active with Ethernet backhaul | Pass |
| LAN | Router, both agents, and unrelated wired services remained reachable | Pass |
| Bridge | Controller-facing and backhaul-facing Ethernet ports remained in the main LAN bridge | Pass |
| WLAN | The exact expected SSID was reported on 2.4 and 5 GHz radios | Pass |
| 6 GHz | The farther agent reported the expected SSID, WPA3-SAE, and 320 MHz operation | Pass |
| Link rate | One directly observed workstation Ethernet link negotiated at 1 Gbit/s | Limited pass |
| Backup | Configuration archive was downloaded, hashed, enumerated, and restored only into an isolated test filesystem | Pass with limitation |
| Full clean SDK build | Stored SDK feeds were incomplete, so an end-to-end clean package rebuild could not finish | Blocked by fixture |

The link-rate observation applies only to the measured workstation link. It is
not evidence that every link in the cascaded backhaul negotiated at the same
rate.

## Safe deployment method

### 1. Capture a baseline

Before changing mesh state, record:

- OpenWrt release, kernel, hardware model, and installed prplMesh package;
- bridge membership and interface link state;
- DHCP leases and current agent addresses;
- controller and transport process state;
- reachability of every service sharing the physical backhaul port;
- existing wireless SSIDs and security modes.

Treat dynamically leased addresses as observations, not stable identity. Match
agents by controller topology identity and Ethernet adjacency as well as by
their current management address.

### 2. Prove the rollback artifact

A downloaded archive is not yet a proven backup. At minimum:

1. calculate and retain a cryptographic hash;
2. enumerate the archive without errors;
3. reject unexpected owners, paths, or missing critical members;
4. extract into an isolated filesystem;
5. compare restored critical files with the source snapshot;
6. document that a physical-device restore remains untested unless it was
   actually performed.

Do not claim a hardware restore from an extraction-only test.

### 3. Preserve the main LAN bridge

The physical Ethernet port carrying the mesh backhaul may also carry ordinary
LAN devices. Moving that entire port into a temporary mesh-only bridge can
disconnect unrelated systems even when the mesh agents themselves remain
reachable.

Before any bridge mutation, enumerate downstream MAC addresses and leases.
Prefer a narrow test that leaves the shared physical port in the main bridge.
If isolation is truly required, first provide a separate physical port or a
deliberately designed VLAN topology.

### 4. Keep one routing authority

OpenWrt remains the only router and DHCP server. Put proprietary devices into
their access-point/EasyMesh-agent operating mode so that they do not introduce
another NAT or DHCP domain. Verify this from the LAN, rather than relying only
on a label in a vendor interface.

### 5. Add agents one at a time

For each agent:

1. connect power and the intended Ethernet backhaul;
2. start the vendor-supported onboarding window;
3. trigger the controller onboarding action once;
4. wait for an active Ethernet adjacency;
5. verify exact SSID and security read-back;
6. retest all unrelated services before adding the next agent.

Repeated button presses or overlapping onboarding windows make the resulting
state difficult to attribute. A single, bounded attempt followed by read-back
produces better evidence.

### 6. Validate exact radio state

A collapsed or substring-based wireless check can hide a wrong 6 GHz SSID.
Validate each band independently and require exact equality. Account for
localized band labels and verify that an unexpected duplicate or suffix does
not pass simply because it contains the desired name.

## Acceptance checks

The following checks are suitable for a non-disruptive acceptance harness:

1. management workstation link state and negotiated speed;
2. controller, both agents, and critical LAN endpoints reachable;
3. expected OpenWrt model, release, and prplMesh package present;
4. controller, agent, transport, and fronthaul processes healthy;
5. required control sockets listening;
6. all shared physical ports still members of the main LAN bridge;
7. no unfinished transition lock or rollback timer active;
8. expected SSID present exactly once per intended radio role;
9. two distinct agents active with Ethernet backhaul;
10. current backup manifest, archive hash, restore-test result, and scheduled
    backup job healthy.

Tests that should remain manual or explicitly disruptive include walking roam
measurements, cable removal, power interruption, factory reset, firmware
upgrade, and a restore onto physical hardware.

## Regression cases that found real defects

![Five lessons from failures to a reproducible deployment](assets/incident-timeline.png)

### Shared-port isolation

**Failure:** a temporary bridge moved the complete downstream Ethernet port out
of the LAN bridge. Unrelated services behind that port disappeared.

**Correction:** restore the port to the main bridge and redesign tests around
the individual mesh protocol path, not the whole shared wire.

**Regression:** fail acceptance if any required physical port leaves the main
bridge or if any declared critical endpoint becomes unreachable.

### Backup archive ownership

**Failure:** configuration content was correct, but one file or symbolic link
was archived with a non-root group owner. A strict restore verifier rejected
the backup.

**Correction:** preserve content, make a scoped metadata backup, correct only
the owner, and rerun archive and isolated-restore verification.

**Regression:** inspect actual archive members, including symbolic links; do not
assume a configuration-file listing covers every archived path.

### Ambiguous radio selection

**Failure:** a fallback configuration lookup could choose an arbitrary access
point when more than one section matched broadly.

**Correction:** fail closed unless exactly one access-point section matches.

**Regression:** cover zero, one, and multiple candidate sections in a pure unit
test.

### Stale-process and stale-log false positives

**Failure:** a controller-only health check or an old transport log could make a
partial stack appear healthy.

**Correction:** require controller, transport, and agent liveness and remove the
old probe log before each isolated run.

**Regression:** kill each component independently and require the stack probe to
fail.

### Permissive MAC parsing

**Failure:** a frame generator accepted a valid-looking MAC followed by trailing
characters.

**Correction:** require the exact 17-character canonical form before emitting a
frame.

**Regression:** normalize only the non-deterministic Message ID, compare every
other byte with a golden frame, and reject short, long, malformed, or
trailing-garbage input.

### Management-session leakage

**Failure:** a diagnostic command could expose a login token or leave a vendor
management session open.

**Correction:** print only non-secret status, restrict read commands to an
allowlist, scope relaxed certificate handling to the device client when
required, and perform best-effort logout in a `finally` path.

**Regression:** capture stdout, reject secret-like response fields, attempt a
forbidden mutation operation, and assert logout after success and failure.

## Automated test layers

![Evidence stack from configuration to real connectivity](assets/evidence-stack.png)

The work used complementary layers rather than treating one emulator as proof
of radio behavior:

- fixture tests for topology parsing, localized band labels, DHCP address
  drift, exact SSID matching, and backup-manifest validation;
- live, read-only acceptance checks for bridge membership, reachability,
  processes, sockets, radio read-back, and controller adjacency;
- Python unit tests for the constrained vendor-management reader;
- native C/C++ tests for frame generation and deterministic configuration
  selection;
- OpenWrt-target cross-compilation syntax checks for changed production code;
- isolated filesystem restore checks for configuration backups.

At the final recorded checkpoint, the combined non-mutating fixture and live
acceptance suite passed 33 of 33 checks with no skips. The constrained vendor
reader passed 8 of 8 unit tests, and the native prplMesh set passed 9 of 9 test
binaries after the modified unit was rebuilt from the current source.

These results cover two distinct artifacts. Live acceptance applies to the
deployed package. Some source-hardening changes and their fresh unit/cross
syntax results were prepared afterward for a future candidate; they were not
rebuilt into or redeployed over the accepted live package during this work.
Publication must preserve that boundary instead of presenting later source
fixes as already deployed.

A fresh full SDK package build was not counted as passing because the retained
SDK fixture lacked required feed packages. Unit tests and target syntax checks
reduce risk but do not replace a reproducible package build.

## Claims this evidence does not support

Do not infer any of the following from the recorded result:

- Wi-Fi Alliance EasyMesh certification;
- complete vendor interoperability;
- 802.11r fast transition;
- MLO control or multi-link backhaul;
- zero-packet-loss or imperceptible client roaming;
- controller ownership of every vendor-specific 6 GHz setting;
- gigabit negotiation or throughput on every Ethernet segment;
- successful disaster recovery onto physical hardware;
- resilience to every reboot, cable, power, or firmware-upgrade sequence.

A physical walking test with packet-loss, association, BSSID, and latency
telemetry is required before making a practical seamless-roaming claim.

## Reproducibility and source provenance

A publishable package recipe should contain an upstream source URL, immutable
commit or release tag, hashes where applicable, and a reviewable patch series.
A local source-directory override is not reproducible and must not be published
as the package recipe.

prplMesh 6.0.1 carries a BSD-2-Clause-Patent project license while parts of its
source tree use additional BSD, ISC, or MIT notices. Preserve upstream
`LICENSE`, `LICENSES`, `AUTHORS`, copyright, and SPDX material. Review the
package metadata so it does not incorrectly reduce a mixed-license tree to a
single incomplete declaration.

Potential upstream contributions should follow the
[prplMesh project](https://gitlab.com/prpl-foundation/prplmesh/prplMesh)
workflow, including its issue-tracking, Developer Certificate of Origin,
`Signed-off-by`, authorship, and source-header requirements.

## Publication safety

Publish from an explicit allowlist, not by copying a working directory. Exclude
private configuration, backups, logs, packet captures, firmware blobs,
proprietary web resources, device-label images, credentials, tokens, real
network identifiers, and management-session material.

This article was prepared with generative-AI assistance. It is not suitable for
verbatim submission to the OpenWrt Forum. See the
[forum evidence note](docs/forum-evidence.md) and re-check the
[current forum guidelines](https://forum.openwrt.org/guidelines) before writing
an independent, personally verified post.
