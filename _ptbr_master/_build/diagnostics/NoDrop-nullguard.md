# No Drop null guard

Original version: 1.3.2.725.
Original SHA256: 668BE85BBDD6D3344041F501E058E5C7E71B2F7C0162B26F32BB79B9250D349F.

The crashes at 14:30:55 and 16:52:24 local time on 2026-11-18 reached `FetchChore_FindFetchTarget.Prefix`, offset 0x58, followed by `GameObject.GetComponent<Pickupable>()`. The carried-item loop did not check whether each Unity object was still alive.

The repair adds a Unity null check before reading each carried item's component, and another check before using the resulting Pickupable. Invalid entries advance to the existing MoveNext instruction. No entries are removed from Storage.items. Valid entries retain the original fetch logic.

Verification: the DLL reopens with Mono.Cecil, both branches target the existing loop continuation, and all short branch displacements remain valid. All 27161 instruction records outside Prefix are unchanged. Prefix grows from 68 to 77 instructions. Gameplay validation is still required after a full restart.

Prepare: `powershell -NoProfile -ExecutionPolicy Bypass -File .\_build\repair-nodrop.ps1`

Install with ONI closed: append `-Install`. The installer preserves the original DLL under `_backups`, checks the installed hash, and refuses unrecognized versions. Steam updates may replace the repaired DLL. Reapply only after reviewing any changed upstream version.
