## Luna Network HSM 7 (A790) Unix Account - (SSH) Password Changer

After creating the Luna Network HSM 7 (A790) Unix Account - (SSH) Password Changer in Secret Server, you must link it to the corresponding Secret Template. 

### Mapping Fields for Custom Templates (RPC):

Follow the official Delinea guide for field mapping here:
- [Mapping Fields for Custom Templates (RPC)](https://docs.delinea.com/online-help/secret-server/rpc-heartbeat/rpc/custom-rpc/mapping-fields-for-custom-templates-rpc/index.htm?Highlight=mapping)

---

### Password Changer Name: Luna Network HSM 7 (A790) Unix Account - (SSH)


---

### Password Changer Command Structure

**Authenticate As:**
- **Username:** `$USERNAME`
- **Password:** `$CURRENTPASSWORD`

---

#### Password Validation (Verify):

| ORDER | COMMAND                     | COMMENT                              | PAUSE (MS) |
|-------|-----------------------------|--------------------------------------|------------|
| 1     | `login -password $PASSWORD` | Login to verify the current password | 2000       |
| 2     | `logout`                    | Logout of the appliance              | 2000       |

---

#### Password Change Commands:

| ORDER | COMMAND                                           | COMMENT                              | PAUSE (MS) |
|-------|---------------------------------------------------|--------------------------------------|------------|
| 1     | `login -password $SECONDARYPASSWORD`              | Authenticate with temporary password | 2000       |
| 2     | `changePw -oldpw $PASSWORD -newpw $NEWPASSWORD`   | Change primary password              | 2000       |
| 3     | `logout`                                          | Logout of the appliance              | 2000       |

---

### Advanced Post-Change Settings:

| SETTING                                                              | VALUE |
|----------------------------------------------------------------------|-------|
| Remote Password Changing Timeout (minutes)                           | 5     |
| Bypass Verify After Password Change                                  | No    |
| Heartbeat Unknown Error to Unable to Connect Translation (regex)     |       |
| Attempt Password Change with new password when error contains (regex)|       |
| Advanced: Delay Verify After Password Change (seconds)               |       |

---

### Template Field Mapping:

The following mapping must be applied between your custom Secret Template and the Luna Network HSM 7 (A790) Unix Account - (SSH) Password Changer:

| Password Type Field | Secret Field |
|---------------------|--------------|
| Machine name        | Machine      |
| Password            | Password     |
| User name           | Username     |

