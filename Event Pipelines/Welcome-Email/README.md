# Introduction

Automate welcome email to all new SS users.

## Permissions

Account creating this requires these role permissions "Administer Pipelines", "Administer Inbox"

## Setup

### Build Event pipeline
Navigate to Admin | Notification Rules and templates | Rules and create a new rule using the following settings

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Rule Name   | Welcome Email                                                                     |
| Message Type | Event Pipeline Send Email Task                                               |
| Template    | Welcome Email                                                                                      |



# Tested on version 11.3
