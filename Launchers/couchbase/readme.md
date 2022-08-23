# Introduction

This document provides the details for creating a customer Launcher for Couchbase Cluster secrets.

## Template

The secret template for Couchbase Cluster can be found here to import: [couchbase_template.xml](../../remote-password-changers/couchbase-accounts/couchbase_template.xml)

## Couchbase Cluster URLs

Couchbase Clusters provide the ability for users to connect using any of the nodes within the cluster. The launcher is configured in a way that allows you to create a single secret for **each cluster**. When you create a secret simply put all the URLs for the cluster in the URL field as a comma-separated list. Example: `http://10.10.10.65:5191, http://10.10.10.66:5191, http://10.10.10.67:5191`. (_Ensure there is a space after the comma._)

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name**
1. Check the box **Use Additional Prompt**
1. Enter `$URL` for the **Additional Prompt Field Name**
1. Enter the **Process Name** for your desired browser (e.g. `chrome`, `msedge` etc.)
1. Enter `"$URL"` for the **Process Arguments** (_include the double-quotes_)
1. Click **Save**

> You may also provide additional arguments if desired for manipulating the browser.

## Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**
1. Click **Add New Launcher**
1. Select `Couchbase` for **Launcher Type to use**
1. Leave `$URL` selection as `<user input>`
1. Set **Domain** to `<blank>`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Check the box **Restrict User Input**
1. **Restrict As** should be set to `Allowed List`
1. **Restrict By Secret Field** should be set to `URL`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
