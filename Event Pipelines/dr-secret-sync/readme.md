> At this time this is an internal document only and **IS NOT** to be shared or given to customers.

# 1. Introduction

# Requirements

The following are the minimum requirements to implement the solution:

- Secret Server 10.8+ Professional or higher
- Webservices enabled in both Secret Server instances
- Secret Server Local Application Account in both instances
- Implement [RPC for Secret Server Local Accounts](../../remote-password-changers/secretserver-local-accounts)
- Provided PowerShell scripts in this document

# Details

This solution addresses the challenge of maintaining an on-premises DR solution while leveraging SSC for daily operations. This solution will provide a synced subset of secrets into an On-Premises Secret Server Instance.

> **WARNING:** This Process is designed to sync a _small_ subset of critical DR Secrets from one instance of SS to another. This does not provide the functionality to support syncing all Secrets in an instance of Secret Server.

## Usage

> **Note:** Users must be manually synced, and the folder structure and RBAC created ahead of time.

This solution will replicate secrets within a folder structure that is already created within SS. The script will create secret templates, that do not exist in the target, so any templates will not need to be created. Files, and "Default" value fields are supported, however the template on the target instance will just get the value set in that dropdown field, **it will not re-create the dropdowns in the DR instance**.

# Configuration Steps

## Webservices

> Webservices will enable other applications to interact with Secret Server via API calls.

1. Navigate to **Admin | Configuration**
2. Under the **General** tab locate **Enable Webservices**
3. Enure this is set to **Yes**
4. Enable it by clicking on the **Edit** button (bottom of the page)
5. Check the box, then click **Save**

![image](https://user-images.githubusercontent.com/11204251/114926034-7925c980-9df5-11eb-8cad-c6b9ea236573.png)

## Create Local Application Account

This solution will require an Application Account to be used by the script for the API calls to the target and source. The application account will need to have appropriate permissions to access and edit any secrets in the target folder location. To create a new Application Account, follow these steps:

a.  Create a new User Account: Go to **Admin | Users | Create New**,
    then fill in **Names** for the account and click **Advanced**. Check
    the **Application Account** box and **Save**.

b.  Duplicate this account on the Target System. The username should be
    the same between the two instances.

c.  Create a new Role for the API Sync User, this role should include
    the following role permissions:

  a.  Source Instance: View Secret Templates

  b.  Target Instance: View Secret Templates, Administer Secret
      Templates

d.  Assign the Created Role to the API user in addition to the normal
    "User Role"

## 4.3 Create Folder Structure To Be Replicated

a.  The Folder Structure will not be automatically Generated into the
    Target Instance.

b.  Create a DR Folder Structure within the Source, this should include
    buckets that make it easy to identify what these DR Secrets are for.

c.  Ensure to create the same folder structure on the Target Instance.
    All Folders should have the same name and folder path must match in
    order for the secret sync to work properly.

## 4.4 Grant Permissions to API account

a.  Go to the folder where all secrets to be synced are located and
    right click on it, then **Edit Folder** | Edit **Folder
    Permissions** and give the application account **view** rights on
    **Folder Permissions** and **EDIT** rights on **Secret Permissions**
    then **Save**.

b.  Replicate the Folder Permission settings on the Target. The Only Exception is that the API User will need Folder Permissions of: "Add Secret" to folders in the Target. 

# 5.  Create Scripts

  a.  Go to **Admin** | **Scripts**.

![image](https://user-images.githubusercontent.com/9537950/108251572-8ee47e80-7125-11eb-8eac-0d000b12fde2.png)

  b. On the PowerShell tab, click
      **+Create New**. The New PowerShell Script window appears:

  c.  Fill in the **Name**, **Description** and **Category** fields.

      **Note**: Select "Untyped" for Category

  d.  Paste your script into the Script text box.

  e.  Click the OK button. The new script will appear in the table on
      the Scripts page.

  f.  Repeat this process for the Local User Password Change, and
      HeartBeat Scripts.

# 6. Create Local User Management Framework

## 6.3 Create Dependency Changer for \"Local API User\"

a.  Navigate to Admin | Remote Password Changing | Configure
    Dependency Changers

![image](https://user-images.githubusercontent.com/9537950/108251892-ff8b9b00-7125-11eb-8b7f-b64674004c1b.png)
![image](https://user-images.githubusercontent.com/9537950/108251928-0a463000-7126-11eb-8008-dfcdfb1d4b28.png)

  i. Choose "Powershell Script" for the type

  ii. Choose "Computer Dependency (Basic) for the Scan Template

  iii. Give it a name, and a description, port can be left blank.

  iv.  Select the "Scripts Tab"

  v. Choose the Local User Password Changing Scripts and supply the
      following Arguments:

  1.  Dependency Change Arguments: `$URL2 $USERNAME $PRIORPASSWORD $PASSWORD`

## 6.4 Create Secret for API Sync User

b.  Populate URL's for SS in respective URL Fields (Source Instance -
    URL, Target Instance - URL2)

c.  Navigate to the Remote Password Changing Tab:

  i.  Edit the field for "Change Password using:"

  ii. Set the PowerShell account under
      this value. This will allow the PowerShell account to run the
      scripts required to change passwords on the local API User.

![image](https://user-images.githubusercontent.com/9537950/108252383-8f314980-7126-11eb-9673-be2a6cc2ac4c.png)

d.  Navigate to the Dependencies Tab

  i.  Create a Dependency to sync password on password change on URL2

  ii. Select "New Dependency"

  iii. Enter the Following Details,

![image](https://user-images.githubusercontent.com/9537950/108252550-c56ec900-7126-11eb-98fb-7eeb57b117c2.png)

  iv. NOTE: ServiceName and Machine Name fields are not used in the
      arguments, so any values can be populated there. The Arguments
      will all pull directly from the secret, but they are required
      fields, so populate test values into those fields.

# 7. Create Event Pipeline Policy

Event Pipelines are a named group of triggers, filters, and tasks to
manage events and responses to them. We will use a pipeline to trigger
running a script to update the secrets by adding a privileged account
upon creation.

## 7.1 "Event Pipelines: Allow Confidential Secret Fields to be used in Scripts" Advanced Setting

For the Event Pipeline to function, the advanced setting: "**Event
Pipelines: Allow Confidential Secret Fields to be used in Scripts"**
must be enabled under the advanced configuration in Secret Server. The
application setting will allow confidential secret fields to be used in
Event Pipeline scripts, such as `$PASSWORD`. The default value is False.

**Note**: Modifying application settings requires an application pool
recycle for on-prem instances.

a.  Go to `https://<SecretServerAddress>/ConfigurationAdvanced.aspx`

b.  Scroll to the bottom and click **Edit**.

c.  Locate the **Event Pipelines: Allow Confidential Secret Fields to be
    used in Scripts** setting and change the value to **True**

d.  Click the **Save** button.

## 7.2 Create the Event Pipeline

a.  Go to **Admin | See all | Actions Category | Event Pipeline Policy**

b.  Click the **Add Policy** button --- the pipeline policy popup window will show up

c.  Fill in the **Policy Name**, **Description** and **Type**.

  **Note**: select **Event Pipeline type**: **Secret**

d.  Click the **Add Pipeline** button.

e.  Click the **Create New Pipeline** button. The **New Pipeline**
    wizard appears on the Choose Triggers page. Create the **Triggers**
    and **Filters** as shown below:

![image](https://user-images.githubusercontent.com/9537950/108252609-dae3f300-7126-11eb-8429-9a490cb96002.png)

f.  For **Task**, enter the following:

  1.  **Script:** Select the Script that we created in earlier steps

  2.  **Run Secret:** Select the secret/account that will run the script
      (SS Powershell Account)

  3.  **Script Arguments**:

      a.  `$[ADD:1]$URL $[ADD:1]$URL2 $SecretID $[ADD:1]$USERNAME $[ADD:1]$PASSWORD $FolderName $FolderPath`

  4.  **Run Site:** Select the site where the script will be executed

  5.  **Additional Secret 1:** Select the
      API secret account that we created in earlier steps

![image](https://user-images.githubusercontent.com/9537950/108252856-1bdc0780-7127-11eb-9fbe-be23171ae975.png)

  6.  Click the Next button. The **Name Pipeline** page of the wizard
      > appears. Enter the **Name**, **Description** and click on
      > **Save**.


g.  Select the **Target** by clicking on the **No Folders Selected**
    > option under the Secret Policy name. This will be all the folders
    > you are looking to Sync into the DR instance.

![image](https://user-images.githubusercontent.com/9537950/113746847-c65aba80-96d4-11eb-9793-022eb79addb8.png)

h.  Activate the Event Pipeline by clicking on the **Active/Inactive** toggle button located on the upper right side of the Event Pipeline policy --- a confirmation popup appears.

![image](https://user-images.githubusercontent.com/9537950/108252914-2d251400-7127-11eb-96a1-04d10eb5fc2d.png)
