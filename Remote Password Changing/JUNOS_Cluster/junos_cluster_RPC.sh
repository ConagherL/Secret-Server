#!/bin/bash
################################################################################
# JUNOS Password Changer - Bash Wrapper with Embedded Expect
#
# This script connects to a JUNOS device via SSH, determines whether the device
# is on a primary or secondary node, switches to the primary node if needed, and
# changes the password for the specified user.
#
# It supports both non-interactive mode (where all parameters are passed on the
# command line) and interactive mode (where the user is prompted for values).
#
# Usage (non-interactive):
#   ./junos_pw_changer.sh <host> <username> <current_password> <new_password>
#
# Usage (interactive):
#   ./junos_pw_changer.sh
#   (You will be prompted for host, username, current password, and new password.)
################################################################################

# Check if exactly four arguments are provided. If yes, use non-interactive mode;
# otherwise, prompt the user for input.
if [ "$#" -eq 4 ]; then
    host="$1"
    username="$2"
    current_pw="$3"
    new_pw="$4"
else
    read -p "Enter host: " host
    read -p "Enter username: " username
    read -s -p "Enter current password: " current_pw
    echo ""
    read -s -p "Enter new password: " new_pw
    echo ""
fi

# Call the embedded Expect script.
expect <<EOF
# Set the timeout (in seconds) for each expect command.
set timeout 20

################################################################################
# SSH Connection Setup
################################################################################

# Spawn an SSH session to the specified host using the provided username.
spawn ssh $username@$host

# Wait for either a password prompt or the JUNOS prompt.
# If a password prompt appears (indicated by "assword:"), send the current password.
expect {
    -re "assword:" {
        send "$current_pw\r"
        # Continue waiting for the JUNOS prompt after sending the password.
        exp_continue
    }
    -re ".*JUNOS.*" {
        # JUNOS prompt received, proceed.
    }
    timeout {
        puts "SSH login timed out or did not receive a JUNOS prompt."
        exit 1
    }
}

################################################################################
# Prompt Evaluation and Node Switching
################################################################################

# Analyze the device prompt to determine if we are on the primary or a secondary node.
expect {
    -re ".*JUNOS.*\n.*primary:node.*\n$username.*>" {
        # Detected a primary node prompt with explicit "primary:node" text.
        puts "Primary node detected. Proceeding with password change."
    }
    -re ".*JUNOS.*\n$username.*>" {
        # Detected a primary node prompt without the explicit "primary:node" text.
        puts "Primary node detected. Proceeding with password change."
    }
    -re ".*secondary:node0.*\n$username.*>" {
        # Detected a secondary node prompt on node0.
        puts "Secondary node0 detected. Switching to node1."
        # Issue the command to switch to node1.
        send "request routing-engine login node 1\r"
        # Wait for the new JUNOS prompt after switching.
        expect {
            -re ".*JUNOS.*" { }
            timeout { puts "Switching to node1 timed out."; exit 1 }
        }
    }
    -re ".*secondary:node1.*\n$username.*>" {
        # Detected a secondary node prompt on node1.
        puts "Secondary node1 detected. Switching to node0."
        # Issue the command to switch to node0.
        send "request routing-engine login node 0\r"
        # Wait for the new JUNOS prompt after switching.
        expect {
            -re ".*JUNOS.*" { }
            timeout { puts "Switching to node0 timed out."; exit 1 }
        }
    }
    timeout {
        puts "No expected prompt detected."
        exit 1
    }
}

################################################################################
# Password Change Process on the Primary Node
################################################################################

# Enter exclusive configuration mode.
puts "Entering exclusive configuration mode."
send "configure exclusive\r"
expect {
    -re ".*>" { }
    timeout { puts "Failed to enter configuration mode."; exit 1 }
}

# Issue the command to set the new plain-text password for the specified user.
puts "Issuing password change command for user $username."
send "set system login user $username authentication plain-text-password\r"
expect {
    -re {.*[Nn]ew.*[Pp]assword.*:} {
        send "$new_pw\r"
    }
    timeout { puts "No prompt for new password received."; exit 1 }
}

# Wait for the confirmation prompt to retype the new password.
expect {
    -re {.*[Rr]etype.*[Pp]assword.*:} {
        send "$new_pw\r"
    }
    timeout { puts "No prompt for password confirmation received."; exit 1 }
}

# Commit the configuration change.
puts "Committing the configuration."
send "commit\r"
expect {
    -re ".*>" { }
    timeout { puts "Commit operation timed out."; exit 1 }
}

# Exit configuration mode.
puts "Exiting configuration mode."
send "exit\r"
expect {
    -re ".*>" { }
    timeout { puts "Failed to exit configuration mode."; exit 1 }
}

# Log out of the device.
puts "Logging out."
send "exit\r"
expect eof

puts "Password change completed successfully."
EOF
