#!/usr/bin/bash
clear
echo "=================
Installing monmon
=================

This install script uses Ansible to deploy monmon to your Raspberry Pi. This means
that Ansible needs to be installed on your LOCAL system (ie. the one you're on right
now), along with any dependencies.

If you do not want to install Ansible and its dependencies on your local system, you
should enter 'n' to cancel the installation."
echo ""
while true; do
    read -p "Do you want to continue? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit; break;;
        * ) echo ""; echo "Please answer y or n"; echo "";;
    esac
done
echo ""
echo ""
while true; do
    read -p "What is the IP address of your Raspberry Pi? (xxx.xxx.xxx.xxx): " ip_address
    if [[ $ip_address =~ ^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
        break
    fi
    echo ""; echo "Please enter a valid IPv4 address"; echo ""
done
echo ""
echo ""
while true; do
    read -p "What is the username on your Raspberry Pi? (press Enter for pi): " pi_user
    pi_user=${pi_user:-pi}
    if [[ $pi_user =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        break
    fi
    echo ""; echo "Please enter a valid username (lowercase letters, digits, _ and -)"; echo ""
done
echo ""
echo ""
echo "# Check for Ansible and prerequisites on local system"
echo "# Needed: ansible, sshpass, and a way for Ansible to hash passwords (passlib)"
echo ""
# Prints the missing tools as generic names: ansible, sshpass, passlib
missing_tools() {
  # Both commands come with Ansible; the hash check below needs the ansible one
  { command -v ansible-playbook && command -v ansible; } >/dev/null 2>&1 || echo ansible
  command -v sshpass >/dev/null 2>&1 || echo sshpass
  # Ask Ansible itself to make a SHA-512 hash, as the playbook does. Newer Ansible can
  # do this on its own; older versions need the passlib Python library.
  if command -v ansible >/dev/null 2>&1
  then
    ansible localhost -i localhost, -c local -m debug \
      -a "msg={{ 'test' | password_hash('sha512') }}" >/dev/null 2>&1 || echo passlib
  fi
}
# Installs the given generic names with apt or pacman, if either is present
install_tools() {
  local packages
  if command -v apt >/dev/null 2>&1
  then
    packages=$(echo "$@" | sed 's/passlib/python3-passlib/')
    echo "# Installing with apt: $packages"
    echo ""
    sudo apt update && sudo apt install -y $packages
  elif command -v pacman >/dev/null 2>&1
  then
    packages=$(echo "$@" | sed 's/passlib/python-passlib/')
    echo "# Installing with pacman: $packages"
    echo ""
    sudo pacman -S --needed $packages
  fi
}
missing=$(missing_tools)
if [[ -z $missing ]]
then
  echo "Everything is already installed"
else
  install_tools $missing
  # Ansible can only be checked for password hashing once it's installed
  missing=$(missing_tools)
  if [[ $missing == passlib ]]
  then
    install_tools passlib
    missing=$(missing_tools)
  fi
  if [[ -n $missing ]]
  then
    echo ""
    echo "These are still missing on your local system: $(echo $missing)

Please install them with your package manager (on Debian/Ubuntu: ansible, sshpass, and
python3-passlib; on Arch: ansible, sshpass, and python-passlib), then run install.sh again.
passlib needs to be installed for the Python that Ansible uses."
    exit 1
  fi
fi
echo ""
if [[ -f config ]]
then
  cp config ansible/config.custom.j2
fi
if [[ -f include.alert_off ]]
then
  cp include.alert_off ansible/include.alert_off.custom.j2
fi
if [[ -f include.alert_on ]]
then
  cp include.alert_on ansible/include.alert_on.custom.j2
fi
if [[ -f monit ]]
then
  cp monit ansible/monit.custom.j2
fi
if [[ -f nodes ]]
then
  cp nodes ansible/nodes.custom.j2
fi
echo ""
echo "# Check the Raspberry Pi's SSH host key"
echo ""
# Ansible won't log in with a password to a host whose key isn't known, and SSH refuses
# one whose key has changed (such as after reflashing the SD card). SSH itself checks the
# key here, so its own settings decide where known keys are kept. No login is attempted.
ssh_probe() {
  ssh -v -o BatchMode=yes -o PreferredAuthentications=none -o ConnectTimeout=10 \
    -o ControlMaster=no -o ControlPath=none "$@" "$pi_user@$ip_address" true 2>&1
}
# The fingerprint of the key the Raspberry Pi presented, from SSH's own output
server_key() {
  tr -d '\r' <<< "$1" | grep -o "Server host key: .*" | head -1 | cut -d' ' -f4-
}
# The name SSH stores the key under: a HostKeyAlias if its settings set one, otherwise
# the host name it connects to, as [name]:port when the port isn't 22
ssh_settings=$(ssh -G "$pi_user@$ip_address" 2>/dev/null)
key_name=$(awk '$1 == "hostkeyalias" {print $2}' <<< "$ssh_settings")
if [[ -z $key_name ]]
then
  key_name=$(awk '$1 == "hostname" {print $2}' <<< "$ssh_settings")
  key_name=${key_name:-$ip_address}
  key_port=$(awk '$1 == "port" {print $2}' <<< "$ssh_settings")
  if [[ -n $key_port && $key_port != 22 ]]
  then
    key_name="[$key_name]:$key_port"
  fi
fi
host_check=$(ssh_probe -o StrictHostKeyChecking=yes)
host_check_status=$?
if [[ $host_check == *"REMOTE HOST IDENTIFICATION HAS CHANGED"* ]]
then
  echo "The SSH host key of $ip_address has changed since this system last connected to it.

If you've reflashed the Raspberry Pi's SD card (or replaced the Pi), that's expected.
Remove the old key with the command below, then run install.sh again:
"
  # SSH names the known hosts file that holds the old key, which may not be the default
  key_file=$(tr -d '\r' <<< "$host_check" | sed -n 's/^Offending .* key in \(.*\):[0-9]*$/\1/p' | head -1)
  if [[ -n $key_file ]]
  then
    echo "  ssh-keygen -f $(printf '%q' "$key_file") -R $(printf '%q' "$key_name")"
  else
    echo "  ssh-keygen -R $(printf '%q' "$key_name")"
  fi
  echo "
If you haven't, don't run it: something else may be answering at that address."
  exit 1
elif [[ $host_check == *"Host key verification failed"* ]]
then
  # A Raspberry Pi this system hasn't connected to before: lets SSH save its key where
  # SSH's settings say, as answering yes to its own prompt would
  ssh_probe -o StrictHostKeyChecking=accept-new > /dev/null
  # Then checks strictly that the key was saved
  host_check=$(ssh_probe -o StrictHostKeyChecking=yes)
  host_check_status=$?
  if [[ $host_check == *"Host key verification failed"* ||
        ( $host_check_status -ne 0 && $host_check != *": Permission denied ("* ) ]]
  then
    echo "Couldn't save the SSH host key of $ip_address:"
    echo ""
    grep -v '^debug' <<< "$host_check"
    exit 1
  fi
  echo "This system hasn't connected to $ip_address over SSH before, so its host key has
been saved:"
  echo ""
  echo "  $(server_key "$host_check")"
elif [[ $host_check_status -ne 0 && $host_check != *": Permission denied ("* ]]
then
  echo "Couldn't connect to $ip_address over SSH:"
  echo ""
  grep -v '^debug' <<< "$host_check"
  echo ""
  echo "Check that the Raspberry Pi is on, connected to your network, and has SSH turned
on, then run install.sh again."
  exit 1
else
  echo "The Raspberry Pi's host key matches the one saved on this system"
fi
echo ""
echo ""
echo "# Run Ansible playbook to deploy monmon to Raspberry Pi"
echo ""
echo "You'll be asked for the current password of the $pi_user user on your Raspberry Pi,
which Ansible uses to log in and to run sudo, and then for an optional new password for
that user. Leave the new password blank to keep the current one. Neither password is
saved anywhere on this system."
echo ""
while true; do
    if ! IFS= read -rsp "Current password for the $pi_user user: " pi_password; then
        echo ""; exit 1
    fi
    echo ""
    if [[ -n $pi_password ]]; then
        break
    fi
    echo ""; echo "Please enter the $pi_user user's current password"; echo ""
done
# The inventory reads it from here, for both SSH and sudo
export MONMON_PI_PASSWORD="$pi_password"
unset pi_password
echo ""
cd ansible
if ! ansible-playbook -i ./inventory-install ./install.yml -e "{\"monmon_ip_address\": \"$ip_address\", \"monmon_user\": \"$pi_user\"}"
then
  echo ""
  echo "The Ansible playbook failed (see the error above), so monmon isn't fully installed.

None of the tasks after the one that failed were run. Setting a new password for the
$pi_user user and scheduling the reboot is the very last task, so if the failure was
anywhere before it, that user still has its current password. If the failure was in that
last task (\"Set the new user password and schedule a reboot\"), the password may or may
not have changed, so try both when you connect. Fix the problem and run install.sh
again."
  exit 1
fi
unset MONMON_PI_PASSWORD
cd ..
echo ""
echo ""
echo "Installation complete!

Your Raspberry Pi is now rebooting to finish the install. It can take
several minutes to come back up, especially on a Pi Zero.

Once it's back up, the monmon status page should be available at http://$ip_address

The Monit web UI should be available at http://$ip_address:2812

About 30 seconds after the Pi is back up, the screen attached to it should briefly turn
green. When this happens, it means that monmon is up-and-running."
echo ""
