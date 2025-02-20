# JUNOS Password Changer - Bash Wrapper with Embedded Expect

This script connects to a JUNOS device via SSH, determines whether the device is on a primary or secondary node, switches to the primary node if needed, and changes the password for the specified user.

## Features

- Supports both non-interactive and interactive modes.
- Automatically switches to the primary node if connected to a secondary node.
- Changes the password for the specified user on the JUNOS device.

## Usage

### Non-Interactive Mode

In non-interactive mode, all parameters are passed on the command line.

```bash
./junos_cluster_RPC.sh <host> <username> <current_password> <new_password>
```

### Interactive Mode

In interactive mode, the user is prompted for values.

```bash
./junos_cluster_RPC.sh
```

You will be prompted to enter the host, username, current password, and new password.

## Requirements

- Bash
- Expect

## Example

### Non-Interactive Mode

```bash
./junos_cluster_RPC.sh 192.168.1.1 admin oldpassword newpassword
```

### Interactive Mode

```bash
./junos_cluster_RPC.sh
```

Follow the prompts to enter the required information.

## Notes

- Ensure that you have the necessary permissions to change the password on the JUNOS device.
- The script sets a timeout of 20 seconds for each expect command. Adjust this value if needed.
