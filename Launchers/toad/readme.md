# Introduction

This document provides the details for creating a custom Launcher for Toad. Toad is an application that is generally used by Oracle DB administrators to connect from their workstations to databases directly, in a similar manner to SQL Server Management Studio for MSSQL databases. 

## Template

The secret template for can be found here to import: 

<details>
  <summary>Click to view XML </summary>

```xml
<?xml version="1.0" encoding="utf-16"?>
<secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <name>Toad Template</name>
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
      <historylength>2147483647</historylength>
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
      <displayname>Server</displayname>
      <description />
      <name>Server</name>
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
      <displayname>Database</displayname>
      <description />
      <name>Database</name>
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
      <fieldslugname>database</fieldslugname>
      <hideonview>false</hideonview>
    </field>
  </fields>
  <descriptions />
  <expirationdays>30</expirationdays>
  <secretnamehistorylength>0</secretnamehistorylength>
  <imageclass>fa-sitemap</imageclass>
  <onetimepasswordenabled xsi:nil="true" />
  <onetimepasswordcodelength xsi:nil="true" />
  <onetimepassworddurationseconds xsi:nil="true" />
  <onetimepasswordhashmode xsi:nil="true" />
  <validatepasswordrequirementsoncreate>false</validatepasswordrequirementsoncreate>
  <validatepasswordrequirementsonedit>false</validatepasswordrequirementsonedit>
  <permissions />
</secrettype>
```
</details>

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Toad Launcher`
1. For **Additional Prompt Field Name** enter: `Server`
1. Enter the **Process Name**: `C:\Program Files\Dell\Toad for Oracle 2016 Suite\Toad for Oracle 12.9\toad.exe`
1. Enter the **Process Arguments**: `-C $username/$password@$Server:1522/$database`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. Click **Save**

# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Toad Launcher for **Launcher Type to use**
1. Set **Domain** to `<blank>`
1. Set **Password** to `Password`
1. Set **Server** to `Server`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
