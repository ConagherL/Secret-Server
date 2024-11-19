# Introduction

This document provides the details for creating a custom Launcher for Active Directory Users and Computers (ADUC). Customers may use this example as a template for launching other MSC's with specific credentials

## Template

The secret template for Active Directory Users and Computers can be found here to import:

<details>
  <summary>Click to view XML </summary>

```xml
  <?xml version="1.0" encoding="utf-16"?>
  <secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <name>ADUC Launcher Template</name>
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
        <displayname>PSHOME</displayname>
        <description>Powershell Home Directory</description>
        <name>PSHOME</name>
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
        <fieldslugname>pshome</fieldslugname>
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
1. Enter a **Launcher Name** ex: `ADUC Launcher`
1. Enter the **Process Name**: `powershell.exe`
1. Enter the **Process Arguments**: `-command "dsa.msc"`
1. Checkmark **Run Process as Secret Credentials** option
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select ADUC Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly. Repeat this process for any other MSCs as needed
