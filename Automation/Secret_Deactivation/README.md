# Automate Secret cleanup by the usage of the secrets

This code allows an organization to output a list of secrets that have not been accessed in over 90 days (configurable) and include the user's (group or user directly assigned) email address. From there, the code has multiple functions. 

One function is to simply call the report. the next function will call the report, deactivate the secrets, and then export the results to a flat file. The final function allows an organization to email the "owners" of the secrets to alert them of the deactivation process.

This code is not meant to be automated but used on an ad-hoc basis to address dead/inactive secrets.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

Automate inactive Secret cleanup within a customer environment

## Features

List the key features of your project.

- Multiple functions in the code to allow different actions
- Updated Help sections to understand the code breakout

## Installation

- This code is dependent on the Thycotic Secret Server PowerShell Module. Please review any additional requirements.
- Requires "Administer Reports" permissions in SS
- API account used must have access to all secrets within scope (Owner Rights)

```bash
$ git clone https://github.com/yourusername/yourproject.git
$ cd yourproject
$ npm install
