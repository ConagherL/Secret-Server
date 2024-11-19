# Introduction

The purpose of this document is to provide details on configuring an
Event Pipeline that can be used to provide ticket validation when
Require Comment is being utilized. This is provided as a workaround to
Thycotic Secret Server's ticket integration when a more robust ticket
validation is required.

## Requirements

1. Secret Server Cloud or Secret Server 10.9 or higher for on-premises

2. Secret Server application user account saved as a secret

3. Infor CRM access required for querying for ticket validation (TBD)

## Prerequisites

### Create PowerShell Script

1. Navigate to **Admin \| Scripts**

2. Create new PowerShell script

3. Provide Name and Description

    a. Category can be left as *Untyped*

4. Copy script in the Appendix at the end of this document.

### Create Secret Server Application User Account

1. Navigate to **Admin | Users**

2. Create new user

3. Click **Advanced**

4. Check box for **Application Account**

Ensure the user is assigned to the target folders for the secrets that
will be monitored using the Event Pipeline.

If granular control is required, the minimum role permissions the secret
should need:

- Add Secret Custom Audit

- View Secret Audit

## Add Audit Report

The report is utilized to obtain the audit entry of the comment where
the ticket is being entered for a given secret. *At this time an
endpoint is not available on the API, so a report is being utilized*.

1. Navigate to Reports

2. Provide Report Name, Report Category (Activity)

3. Past the following query below.

4. Click **Save**

## Event Pipeline Configuration

1. Navigate to **Admin | See All | Event Pipeline Policy**

2. Create Event Pipeline Policy

3. Select Secret as the policy type

4. Create Event Pipeline

5. Add Secret Trigger: **View**

6. Add Secret Filter: **Secret Setting**

    a.  Setting Name: *Require View Comment*
    b.  Value Match Type: *Equals*
    c.  Value: *true*

7. Add Secret Task: **Run Script**

    a.  Select script
    b.  Use Site to Run as Secret (checked)
    c.  Run Secret (ignored if using site)
    d.  Script Args (***space between each argument***):

        ```console
        "https://<your Secret Server URL>" $[ADD:1]$USERNAME $[ADD:1]$PASSWORD ReportID $SecretId "$MAS Account Number" $ByUser $EventUserId
        ```

    e.  Additional Secret: Add the Secret Server application user for
        API calls
        i.  This account requires edit rights to the secrets (needed to write custom audit entry)
    f.  Save
