# Introduction

This document provides the details for creating a custom Launcher for HeidiSQL. HeidiSQL is an open source application that be used as a launcher for MariaDB / MySQL, Microsoft SQL, PostgreSQL and SQLite. The process arguments below specifiy that it is using MySQL however this can be adapted for the other protocols/servers mentioned. A list of what to specify is here https://www.heidisql.com/help.php#commandline 
Application websbite: https://www.heidisql.com/ 

## Template

The secret template for can be found here to import: 

<details>
  <summary>Click to view XML </summary>

```xml
<?xml version="1.0" encoding="utf-16"?>
<secrettype xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <name>HeidiSQL</name>
  <active>true</active>
  <fields>
    <field isexpirationfield="false">
      <displayname>Server</displayname>
      <description>The server name or IP Address for the MySql instance.</description>
      <name>Server</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>10</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>true</required>
      <fieldslugname>server</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="false">
      <displayname>Username</displayname>
      <description>The username or userid of the MySql account.</description>
      <name>Username</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>false</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>10</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>true</required>
      <fieldslugname>username</fieldslugname>
      <hideonview>false</hideonview>
    </field>
    <field isexpirationfield="true">
      <displayname>Password</displayname>
      <description>The password of the user.</description>
      <name>Password</name>
      <mustencrypt>true</mustencrypt>
      <isurl>false</isurl>
      <ispassword>true</ispassword>
      <isnotes>false</isnotes>
      <isfile>false</isfile>
      <passwordcharacterset />
      <passwordlength>10</passwordlength>
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
      <passwordlength>10</passwordlength>
      <historylength>2147483647</historylength>
      <isindexable>true</isindexable>
      <editablepermission>2</editablepermission>
      <required>false</required>
      <fieldslugname>notes</fieldslugname>
      <hideonview>false</hideonview>
    </field>
  </fields>
  <expirationdays>30</expirationdays>
  <secretnamehistorylength>0</secretnamehistorylength>
  <imageclass>icon-ss-database</imageclass>
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
1. Enter a **Launcher Name** ex: `HeidiSQL Launcher`
1. For **Additional Prompt Field Name** enter: `SERVER`
1. Enter the **Process Name**: `C:\Program Files\HeidiSQL\heidisql.exe`
1. Enter the **Process Arguments**: `-n 0 -h $SERVER -l libmysql.dll -u $USERNAME -p $PASSWORD `
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**

# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select HeidiSQL Launcher for **Launcher Type to use**
1. Set **Domain** to `<Blank>`
1. Set **Password** to `Password`
1. Set **SERVER** to `Server`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
