# Introduction

This document provides the details for creating a custom Launcher for NetUse. There are two different examples provided. One is for use explicitly with Powershell, while the other is for use with a batch (.bat) file.  Please follow the appropriate steps for the one applicable for you. 

## Template 1 (Powershell)

The secret template for NetUse (Powershell) can be found below:

<details>
  <summary>Click to view XML </summary>

```xml
<?xml version="1.0" encoding="utf-16"?>
<secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <name>NetUse Template</name>
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
      <displayname>PATH</displayname>
      <description>Path of Network Share</description>
      <name>PATH</name>
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
      <fieldslugname>path</fieldslugname>
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

## Template 2 (Batch File)

The secret template for NetUse (Batch) can be found below:

<details>
  <summary>Click to view XML </summary>

```xml
<?xml version="1.0" encoding="utf-16"?>
<secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <name>NetUse Bat Template</name>
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
      <displayname>PATH</displayname>
      <description>Path of Network Share</description>
      <name>PATH</name>
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
      <fieldslugname>path</fieldslugname>
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

# Create Launcher (Powershell)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `NetUse Powershell Launcher`
1. Enter the **Process Name**: `powershell.exe`
1. Enter the **Process Arguments**: `net use r: $PATH /user:$DOMAIN\$USERNAME $PASSWORD /p:no`
1. Checkmark **Wrap Custom Parameters with Quotation Marks**
1. Click **Save**

# Create Launcher (Batch)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Choose the **Launcher Type** of Batch File 
1. Enter a **Launcher Name** ex: `NetUse Batch Launcher`
1. Create a batch file that contains the following commands and then upload it to the **Batch File** section under windows settings

  ```console
  net use m: %1 /user:%2\%3 %4 /p:no
  pause
  ```
1. Enter the **Process Arguments**: `$PATH $DOMAIN $USERNAME $PASSWORD`
1. Checkmark **Wrap Custom Parameters with Quotation Marks**
1. Click **Save**

Create a secret and test/verify the launcher functions properly. 

# Configure Template Launcher (PowerShell) 

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select NetUse Powershell Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

# Configure Template Launcher (Batch) 

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select NetUse Batch Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly. 
