# 🌟 PowerShell SDK for Secret Server

A practical guide to setting up the Secret Server **SDK Client** (`tss`) so an
application or script can read secrets **without storing a password**.

Works against Secret Server (on-prem 10.4+) and Secret Server Cloud, including
Platform-fronted SSC tenants.

> **The two things that break a fresh client:** the **permission model** (§5 — you
> need *both* a share and a role) and **DPAPI binding** (§3 — the same Windows user
> that runs `init` must run the reads). Read those two sections first.

---

## 1. How it works (30-second version)

1. An admin creates an **SDK Client Rule** tied to a Secret Server identity (an
   application account; on the Platform, a **service user** whose app account is
   auto-created).
2. The rule yields an **onboarding key**.
3. On the client machine you run `tss init` once with the URL, rule name, and key.
4. The machine now holds its own **encrypted** credential. Your app calls
   `tss secret -s <id> -f password` — no password in code, no token juggling.

The client can only read what its identity is allowed to (see §5).

---

## 2. Recommended directory layout

Keep the binaries separate from per-identity config, and config separate from keys:

```plaintext
E:\SDK\
├── SecretServerSDK\              # the tss client (tss.exe + libraries)
└── SDK_Profiles\
    ├── <ACCOUNT_A>\
    │   ├── Config\               # connection details (read on every call)
    │   ├── Keys\                 # encryption key (used at init / migration)
    │   └── Logs\
    └── <ACCOUNT_B>\
        ├── Config\
        ├── Keys\
        └── Logs\
```

One `Config`/`Keys` pair **per identity** lets several run side by side on one host.

---

## 3. DPAPI: same Windows user, interactive or batch logon

On Windows the stored credential is encrypted with **DPAPI**, bound to the **Windows
user** that ran `tss init`. This has consequences that cause confusing failures:

- **Run `init` as the identity that will run the reads** (service account /
  scheduled-task / app-pool identity). A different Windows user — even an admin —
  cannot decrypt it.
- A second Windows user touching the profile **corrupts the key** →
  `Error occurred during a cryptographic operation`, and the stored credential gets
  cleared (`Secret Server credentials not present`).
- **DPAPI does not work over a WinRM network logon.** `init`/reads must run in an
  **interactive** logon (the machine's console) or a **batch** logon (a scheduled
  task with a stored password). A remote `Invoke-Command` session will throw the
  crypto error even as the correct user.
- Multiple `init`s into the *same* config directory will corrupt it — use
  `--if-not-exist` and a separate directory per identity.

> **On Linux** there is no DPAPI — lock down the config/key files yourself
> (`chmod 600`).

---

## 4. Prerequisites in Secret Server

1. **Enable the SDK / web services** (Admin → SDK Client Management; Admin →
   Configuration → enable web services).
2. **Create the identity** the rule will use:
   - On a **Platform-fronted tenant**, create a **Service User** (Access → Users →
     More → *Add service user*). Secret Server auto-creates a matching
     **application account** — that's what the SDK rule binds to. (A *regular*
     Platform user does **not** get one.)
   - On a **standalone Secret Server**, create an **Application Account** user.
3. **Assign a role with the View Secret capability** to that identity — see §5.
4. **Share the target secret(s)** with the identity (View).

---

## 5. Permissions: the two layers (this is what bites)

To read a secret through the SDK, the identity needs **BOTH**:

| Layer | What | Where |
|---|---|---|
| **Share** | View on the secret (or its folder) — gates *which* secrets | Secret → Sharing, or folder permissions |
| **Role / capability** | A role granting **View Secret** (+ **View Launcher Password on Secrets**) — the *capability* to view a secret's contents | Platform: Access → Roles + assign to the user/group. Standalone SS: a Role with the equivalent permission |

**Symptom if the role is missing:** the identity can **list/find** the secret but a
read returns `400 API_UserDoesNotHaveViewSecretPermission`. Platform **service users
have no roles by default** (excluded from "Everybody"), so this is the common trap —
the share looks right, but the role is absent.

**Scoping caveat:** if the role grants *unrestricted* secret view, the identity can
read any secret regardless of share. To restrict an identity to specific
folders/secrets, give it a **least-privilege** role (View Secret capability *without*
view-all) and let the **share** do the gating.

---

## 6. Create the SDK Client Rule (UI only — no REST API)

Admin → **SDK Client Management** → **Client Onboarding** → **+ Create Rule**:

- **Name** (no spaces), e.g. `app-a-rule`.
- **Application account**: the identity from §4.
- **Require Onboarding Key**: ✅ (strongly recommended — otherwise any client in the
  IP range can enroll).
- *(Optional)* **Allowed IP Ranges (CIDR)** — IPv4 only.
- Save → open the rule → **Show Key** → copy the onboarding key.

---

## 7. Initialize a profile (`tss init`) — once per identity

Run **as the Windows user that will run the reads** (see §3), on the console or via a
batch logon:

```powershell
E:\SDK\SecretServerSDK\tss.exe init `
    --url            https://YOURTENANT.secretservercloud.com `
    --rule-name      app-a-rule `
    --onboarding-key <key from the rule> `
    --config-directory E:\SDK\SDK_Profiles\<ACCOUNT_A>\Config `
    --key-directory    E:\SDK\SDK_Profiles\<ACCOUNT_A>\Keys `
    --if-not-exist
```

| Flag | Short | Purpose |
|---|---|---|
| `--url` | `-u` | URL of your Secret Server / SSC tenant |
| `--rule-name` | `-r` | The SDK Client Rule name from §6 |
| `--onboarding-key` | `-k` | Key shown on the rule |
| `--config-directory` | `-cd` | Where connection config is stored |
| `--key-directory` | `-kd` | Where the encryption key is stored |
| `--if-not-exist` | `-e` | Skip if already initialized (don't corrupt an existing profile) |

### 📄 Config vs. 🔑 Key
- **Config** — connection details + SDK settings; read on **every** call.
- **Key** — encrypts the cached credential/token; used at **init / migration** only.
  Store it separately and protect it.

---

## 8. Use it

Reads pass only the directories — no URL, key, or password:

```powershell
$tss = "E:\SDK\SecretServerSDK\tss.exe"
$cd  = "E:\SDK\SDK_Profiles\<ACCOUNT_A>\Config"
$kd  = "E:\SDK\SDK_Profiles\<ACCOUNT_A>\Keys"

& $tss secret --secret 123 --field password -cd $cd -kd $kd   # one field
& $tss secret --secret 123 --as-dictionary  -cd $cd -kd $kd   # all fields (key=value)
& $tss token  -cd $cd -kd $kd                                 # short-lived token for your own REST calls
& $tss status -cd $cd -kd $kd                                 # connection status
```

**Caching** (per profile): `tss cache --strategy <0-3> --age <minutes>`
- `0` Never · `1` Server-then-cache · `2` Cache-then-server · `3` Cache-then-server with fallback.
- `tss cache --current` to view · `tss cache --bust` to clear.

---

## 9. Sample script (token + read, with logging)

```powershell
$tss = "E:\SDK\SecretServerSDK\tss.exe"
$cd  = "E:\SDK\SDK_Profiles\<ACCOUNT_A>\Config"
$kd  = "E:\SDK\SDK_Profiles\<ACCOUNT_A>\Keys"
$log = "E:\SDK\SDK_Profiles\<ACCOUNT_A>\Logs\sdk.log"

# Prove the enrolled credential works
$token = (& $tss token -cd $cd -kd $kd 2>&1 | Out-String).Trim()
if ([string]::IsNullOrWhiteSpace($token) -or $token -match '(?i)error') {
    Add-Content $log "$(Get-Date -Format o) | TOKEN | FAIL | $token"
    throw "SDK token retrieval failed."
}
Add-Content $log "$(Get-Date -Format o) | TOKEN | OK"

# Retrieve a secret field
$pw = (& $tss secret --secret 123 --field password -cd $cd -kd $kd 2>&1 | Out-String).Trim()
if ($pw -match '(?i)denied|not have|error') {
    Add-Content $log "$(Get-Date -Format o) | READ 123 | FAIL | $pw"
    throw "Secret read failed: $pw"
}
Add-Content $log "$(Get-Date -Format o) | READ 123 | OK"
# ... use $pw ...
```

---

## 10. Security guidance

- Always **Require Onboarding Key**; optionally restrict by **IPv4 CIDR**.
- Use a **dedicated, least-privilege** identity per app — never an admin account.
- Run `init` (and reads) as the **service identity**, not a personal admin login.
- Keep **Keys** separate and protected; it's only needed at init/migration.
- Tune **caching** to your freshness vs. resilience needs; revoked access can be
  masked by an aggressive cache (and client revocation has a ~15-minute tail).
- Review **SDK Client Management → audit** for enrollment and access events.
- Do **not** initialize multiple SDK accounts into the same directory — it invalidates
  existing configurations.

---

## 11. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `400 API_UserDoesNotHaveViewSecretPermission` | Missing the **role** (View Secret) on the identity, and/or no **share** on the secret. Both layers are required (§5). |
| Reads fail right after init (`cryptographic operation` / "credentials not present") | Running as a **different Windows user** than enrolled, or over a **WinRM network logon** (DPAPI). Run as the enrolling identity on the console or via a batch logon (§3). |
| `API_RuleDoesNotMatch` | Client IP outside the rule's CIDR, or wrong rule name / onboarding key. |
| "already initialized" | Config directory was initialized before — use `--if-not-exist` or a fresh directory. |
| Stale values after a change | Caching — `tss cache --bust` or set strategy `0`. |

---

## References

- Using the SDK for DevOps — <https://docs.delinea.com/online-help/secret-server/api-scripting/sdk-devops/using-sdk/index.htm>
- SDK CLI reference — <https://docs.delinea.com/online-help/secret-server/api-scripting/sdk-devops/sdk-cli/index.htm>
- SDK downloads (latest **1.6.2**) — <https://docs.delinea.com/online-help/secret-server/api-scripting/sdk-devops/sdk-downloads/index.htm>
- Adding service users (Platform) — <https://docs.delinea.com/online-help/delinea-platform/users/add-users.htm>
