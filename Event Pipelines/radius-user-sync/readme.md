# Introduction

After an initial synchronization of AD happens, a RADIUS username will always reflect the initial user synchronized from AD. If the username changes in AD and is synchronized to Secret Server, the username to log in to Secret Server will change, but the RADIUS username will not be updated. This event pipeline ensures that the AD username and RADIUS username are updated to match one another. 


# Create Scripts

  a.  Go to **Admin** \> **Scripts**.

![image](https://user-images.githubusercontent.com/9537950/108251572-8ee47e80-7125-11eb-8eac-0d000b12fde2.png)
    
  b. On the PowerShell tab, click
      **+Create New**. The New PowerShell Script window appears:

  c.  Fill in the **Name**, **Description** and **Category** fields.

 **Note**: Select "Untyped" for Category

  d.  Paste your script into the Script text box. [UpdateUserRADIUSPipeLine.ps1](UpdateUserRADIUSPipeLine.ps1)

  e.  Click the OK button. The new script will appear in the table on
      the Scripts page.

## Webservices

> Webservices will enable other applications to interact with Secret
> Server via API calls.

a.  Navigate to **Admin \| Configuration \| General** tab
    and **Edit** to **Enable Webservices**. Check the box, then
    click **Save**.

![image](https://user-images.githubusercontent.com/9537950/108111924-698f3c00-7063-11eb-828f-703e280ffd1b.png)

## Create API Account 

This solution will require an application account to be used by the
script. The application account will need to have appropriate
permissions to modify users. To create a new Application Account, follow these steps:

a.  Create a new User Account: Go to **Admin \| Users \| Create New**,
    then fill in **Names** for the account and click **Advanced**. Check
    the **Application Account** box and **Save**.

b.  Duplicate this account on the Target System. The username should be
    the same between the two instances.

c.  Create a new Role for the API RADIUS Sync User, this role should include
    the following role permissions:

  a.  Administer Users

d.  Assign the Created Role to the API user 

## Create Secret for RADIUS User Sync

Populate URL for SS in respective URL Field. A secret using the default Website Template can be leveraged for this pipeline


# Create Event Pipeline Policy

Event Pipelines are a named group of triggers, filters, and tasks to
manage events and responses to them. We will use a pipeline to trigger
running a script to update the secrets by adding a privileged account
upon creation. When creating the Pipeline policy, please configure it as a user policy.

## "Event Pipelines: Allow Confidential Secret Fields to be used in Scripts" Advanced Setting

For the Event Pipeline to function, the advanced setting: "**Event
Pipelines: Allow Confidential Secret Fields to be used in Scripts"**
must be enabled under the advanced configuration in Secret Server. The
application setting will allow confidential secret fields to be used in
Event Pipeline scripts, such as \$PASSWORD. The default value is False.

**Note**: Modifying application settings requires an application pool
recycle for on-prem instances.

a.  Go to
    https://\<SecretServerAddress\>/**ConfigurationAdvanced.aspx.**

b.  Scroll to the bottom and click **Edit**.

c.  Locate the **Event Pipelines: Allow Confidential Secret Fields to be
    used in Scripts** setting and change the value to **True**

d.  Click the **Save** button.

## Create the Event Pipeline

a.  Go to **Admin** \| **See all \| Actions Category \| Event Pipeline
    Policy**

b.  Click the **Add Policy** button --- the pipeline policy popup window
    will show up

c.  Fill in the **Policy Name**, **Description** and **Type**.

  **Note**: select **Event Pipeline type**: **Secret**

d.  Click the **Add Pipeline** button.

e.  Click the **Create New Pipeline** button. The **New Pipeline**
    wizard appears on the Choose Triggers page. Create the **Triggers**, **Filters**, and **Task**:

1.  **Trigger:** This should be set to User:Edit
2.  **Filters:** This should be set to Event User: User Setting. For the User Setting name, choose "Is System User", for Value Match Type choose "Equals", and for the Value, enter "True"
3. **Tasks:** For the task choose Run Script and attach the script made from the previous step

f.  For **Task**, enter the following:


  1.  **Script:** Select the Script that we created in earlier steps

  2.  **Run Secret:** Select the secret/account that will run the script
      (SS Powershell Account)

  3.  **Script Arguments**:

      a.  \$\[ADD:1\]$USERNAME \$\[ADD:1\]$PASSWORD $TargetUserID

  4.  **Run Site:** Select the site where the script will be executed

  5.  **Additional Secret 1:** Select the
      API secret account that we created in earlier steps

6.  Click the Next button. The **Name Pipeline** page of the wizard appears. Enter the **Name**, **Description** and click on **Save**.

7. Activate the Event Pipeline by clicking on the **Active/Inactive** toggle button located on the upper right side of the Event Pipeline policy --- a confirmation popup appears.

