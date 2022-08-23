# Introduction

This document provides the details for creating custom Launchers primarily for SQL Server Management Studio versions 18. One example is provided to support a launcher with local SQL authentication for older versions of SQL management Studio that still support the -P switch.

## Template

Since there are multiple launcher options that we have provided in the details below, we have created a template that contains fields that accomodate all of the launchers. Modify the template, once imported, to match the variables that you intend to use for the launcher that works best for your use case.

<details>
  <summary>Click to view XML </summary>

```xml
<?xml version="1.0" encoding="utf-16"?>
<secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <name>SQL Management Studio Generic Template</name>
  <active>true</active>
  <fields>
    <field isexpirationfield="false">
      <displayname>Domain</displayname>
      <description>The Server or Location of the Active Directory Domain.</description>
      <name>Domain</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>12</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>domain</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>Username</displayname>
      <description>The Domain Username.</description>
      <name>Username</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>12</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>true</required>
      <fieldslugname>username</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="true">
      <displayname>Password</displayname>
      <description>The password of the Domain User.</description>
      <name>Password</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>true</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>12</passwordlength>
      <historylength>0</historylength>
      <isindexable>false</isindexable>
      <editablepermission>2</editablepermission>
      <required>true</required>
      <fieldslugname>password</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>Notes</displayname>
      <description>Any additional notes.</description>
      <name>Notes</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>true</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>12</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>notes</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>server</displayname>
      <description />
      <name>server</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>-1</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>false</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>server</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>instance</displayname>
      <description />
      <name>instance</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>-1</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>false</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>instance</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>port</displayname>
      <description />
      <name>port</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>-1</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>false</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>port</fieldslugname>
      <hideonview>false</hideonview>
    </field>
  </fields>
  <descriptions />
  <expirationdays>30</expirationdays>
  <secretnamehistorylength>0</secretnamehistorylength>
  <imageclass>fa-sitemap</imageclass>
  <onetimepasswordenabled>false</onetimepasswordenabled>
  <onetimepasswordcodelength xsi:nil="true" />
  <onetimepassworddurationseconds xsi:nil="true" />
  <onetimepasswordhashmode xsi:nil="true" />
  <validatepasswordrequirementsoncreate>false</validatepasswordrequirementsoncreate>
  <validatepasswordrequirementsonedit>false</validatepasswordrequirementsonedit>
  <permissions />
</secrettype>
```
</details>

# Create SQL Mgmt Domain User Launcher

This launcher for SQL management studio is useful for launching SQL management studio with Windows Authentication for a domain user account that has access to the specific server and instance that is provided in the Server and Instance fields, respectively. Please note that this is using SQL Server Management Studio 18. Adjust filepath to SSMS.exe as required

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `SQL Mgmt Domain User Launcher`
1. Enter the **Process Name**: `C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe`
1. Enter the **Process Arguments**: `-E -S $server\$instance`
1. Checkmark **Run Process as Secret Credentials** option
1. Checkmark **Load User Profile** option
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template - SQL Mgmt Domain User Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select SQL Mgmt Domain User Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.

# Create SQL Mgmt Domain User Custom Port Launcher

This launcher for SQL management studio is an alternative to the first option that will launch SQL management studio with Windows Authentication for a domain user account that leverages a custom port

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `SQL Mgmt Domain User Custom Port Launcher`
1. Enter the **Process Name**: `C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe`
1. Enter the **Process Arguments**: `-E -S "$Username Input",$Port`
1. Checkmark **Run Process as Secret Credentials** option
1. Checkmark **Load User Profile** option
1. Click **Save**

# Configure Template - SQL Mgmt Domain User Custom Port Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select SQL Mgmt Domain User Custom Port Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**


Create a secret and test/verify the launcher functions properly.


# Create SQL Server Launcher Local User

This launcher for SQL management studio is for local SQL User authentication and is only applicable on SQL Server Management Studio versions **Below** 18. Versions 18 and above no longer support the -P switch.

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `SQL Server Launcher Local User`
1. Enter the **Process Name**: `C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe`
1. Enter the **Process Arguments**: `-S $Server -U $Username -P $Password`
1. Leave **Run Process as Secret Credentials** option unchecked
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template - SQL Server Launcher Local User

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select SQL Server Launcher Local User for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**
