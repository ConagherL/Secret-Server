# Introduction

This script can be used to create local users in Secret Server from a CSV file. The CSV file must include the columns specified in the script.

> **Note:** The script will need modified to include your specific Secret Server instance URL in the format of https://SSURL

> **Note:** This script may be good for one off bulk additions of local users within Secret Server, but we do not recommend hardcoding a username and password into this script for long term use. Please ensure that the user that runs the script has appropriate role permissions in Secret Server to create user accounts.
