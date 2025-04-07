## Luna HSM SSH Password Changer Commands Structure

### Authenticate As:
- **Username:** `$USERNAME`
- **Password:** `$CURRENTPASSWORD`

---

### Password Validation (Verify):

| ORDER | COMMAND                     | COMMENT                              | PAUSE (MS) |
|-------|-----------------------------|--------------------------------------|------------|
| 1     | `login -password $PASSWORD` | Login to verify the current password | 2000       |
| 2     | `logout`                    | Logout of the appliance              | 2000       |

---

### Password Change Commands:

| ORDER | COMMAND                                       | COMMENT                              | PAUSE (MS) |
|-------|-----------------------------------------------|--------------------------------------|------------|
| 1     | `login -password $SECONDARYPASSWORD`          | Authenticate with temporary password | 2000       |
| 2     | `changePw -oldpw $PASSWORD -newpw $NEWPASSWORD` | Change primary password              | 2000       |
| 3     | `logout`                                      | Logout of the appliance              | 2000       |

---

### Advanced Post-Change Settings:

| SETTING                                                           | VALUE |
|-------------------------------------------------------------------|-------|
| Remote Password Changing Timeout (minutes)                        | 5     |
| Bypass Verify After Password Change                               | No    |
| Heartbeat Unknown Error to Unable to Connect Translation (regex)  |       |
| Attempt Password Change with new password when error contains (regex) |     |
| Advanced: Delay Verify After Password Change (seconds)            |       |
