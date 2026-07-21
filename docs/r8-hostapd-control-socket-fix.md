# prplMesh r8: OpenWrt hostapd control-socket source fix

Status: sanitized engineering evidence
Evidence checkpoint: 2026-07-21

## Outcome

prplMesh 6.0.1-r8 is the accepted live package at this checkpoint. It contains
a source-level fix for the hostapd control-socket regression exposed by the r6
build. A later hardware reboot changed the boot identity. Normal and recovery
SSH listeners on TCP 22 and 2222 returned in about 19 seconds, both proprietary
EasyMesh agents were active with Ethernet backhaul in about 35 seconds, `lan2`
and `lan3` remained in the main LAN bridge at 1000/full, and the complete
post-reboot read-only live acceptance suite passed 19 of 19 checks.

That paragraph is the historical hardware-reboot checkpoint. At a later final
controller-restart checkpoint, both agents again returned Active/Ethernet
behind one occupied controller-side uplink negotiated at 1000/full, while an
unused port remained a main-bridge member with no carrier. LiveSafe r8 passed
19/19 with no skips. This later result is not another hardware-reboot test and
does not prove the agent-to-agent segment speed.

This result is narrower than a universal recovery or interoperability claim.
The second wired-path throughput was not run, and walking roam was skipped and
not run. It does not establish 802.11r/FT, mesh-wide MLO, or physical-device
restore.

## Failure and root cause

The r6 package was reproducible, but its wireless control library was built
against pristine upstream hostapd sources without an OpenWrt-specific socket
permission patch. The controller processes started, yet the topology became
empty and both local fronthaul processes repeatedly restarted.

The failure path was:

1. the control client created a local UNIX datagram socket owned for its own
   execution context;
2. hostapd, running inside the OpenWrt sandbox under a restricted identity,
   received a `STATUS` request;
3. hostapd could not send the reply to that client socket;
4. the wireless abstraction layer timed out while refreshing radio state;
5. both fronthaul processes restarted and agent onboarding could not complete.

Binary inspection agreed with the source diagnosis: the working and fixed
implementations contained the socket permission/ownership calls, while the
regressed implementation did not.

## r8 source correction

The r8 recipe makes the formerly implicit OpenWrt dependency explicit:

- pin the upstream hostapd revision and archive hash;
- verify the unmodified control-client source hash;
- apply the official OpenWrt
  `610-hostapd_cli_ujail_permission.patch` exactly once;
- verify the patched source hash before compilation;
- use the SDK's explicit host `mkhash` executable rather than an undefined
  build macro;
- build without network access;
- package only prplMesh components, never replacement system Wi-Fi daemons.

The OpenWrt patch adjusts the local control-socket mode and ownership so the
sandboxed hostapd process can reply to the client. r8 therefore fixes the
source recipe instead of carrying forward a binary copied from an older build.

The resulting r8 APK is 4,537,338 bytes. Its complete artifact identity was
verified before installation but is omitted from this narrative evidence note.

## Verification

| Gate | Result |
|---|---|
| Exact source and official patch inputs | Verified before build |
| Patch application and patched-source identity | Pass |
| Network-disabled package build | Pass |
| Hostapd control-socket compatibility suite | 9/9 pass |
| r8 APK artifact suite | 11/11 pass |
| APK integrity and extraction | Pass; 32 payload files |
| Replacement `wpad`, `hostapd`, or `wpa_supplicant` payload | Absent |
| Shell syntax and static checks for the installer | Pass |
| Configuration preservation across installation | Pass |
| Initial live stability window | Pass; process identities remained stable |
| Controlled service restart | Pass |
| Post-service-restart live acceptance | 19/19 pass; two active Ethernet agents |
| Historical hardware reboot with r8 installed | Pass; boot identity changed |
| Historical management listeners after reboot | TCP 22 and 2222 returned in about 19 seconds |
| Historical agent convergence after reboot | Two active Ethernet agents in about 35 seconds |
| Historical required Ethernet ports after reboot | `lan2` and `lan3`, main LAN bridge, 1000/full |
| Historical post-reboot live acceptance | 19/19 pass |
| Final controller-restart acceptance | Two Active/Ethernet agents; occupied controller-side uplink 1000/full; unused main-bridge port idle/no carrier; LiveSafe 19/19, no skips |

The live package identity, service-restart result, hardware-reboot result, and
controller topology were checked independently of the local build result. A
successful compiler exit alone was not accepted as deployment evidence.

## Mixed-vendor 6 GHz guard boundary

The farther agent's vendor interface reported the expected 6 GHz SSID,
WPA3-SAE, and 320 MHz state at the checkpoint. However, the agent does not
expose a 6 GHz radio identifier in the controller-visible radio inventory.
Consequently, a standard controller-side check cannot uniquely bind the
vendor-managed 6 GHz profile to that radio.

A separate fail-closed compensating guard is now live-verified. At the final
controller session it detected vendor-profile drift, restored the exact
expected SSID, WPA3-SAE, and 320 MHz profile with one allowlisted combined
write, and then:

- requires the exact expected radio hardware identity without publishing it;
- discovers the current management address dynamically from DHCP state;
- requires a verified off-device backup before mutation;
- permits one allowlisted combined write only when drift is proven;
- rechecks at 12, 60, and 180 seconds and requires each result to be `NOOP`;
- exits early on a second call in the same session, before evidence collection,
  vendor API access, or any write.

This guard controls vendor-local configuration drift. It is not a prplMesh core
feature and does not make the absent controller-visible 6 GHz radio identity
appear in the standard topology.

## Publication boundary

Do not publish credentials, real wireless names, management addresses, device
identifiers, backup locations, raw logs, or management-session material. Do not
generalize the single successful hardware reboot to every power, cable, reset,
upgrade, or disaster-recovery sequence.
