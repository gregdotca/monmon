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
echo "NOTE: Both the GUI and CLI methods mentioned below are experimental"
echo ""
echo "monmon has a very minimal status page built-in, and in addition to having the 
Waveshare 1.3\" display flash when there's an issue with one of your Monit instances,
you can also (optionally) hookup an external HDMI display to the Pi and have it load
the monmon status page automatically at boot.

If you have no intention of hooking up an external HDMI display, then simply enter none
and ignore the rest of this text.

If you want to go with the GUI display method, type gui and the PIXEL desktop
environment will be installed and automatically loaded at boot, with the monmon Status
Page loading in the lightweight Midori web browser. Although this method is technically
possible, it's still pretty heavy for a Pi Zero 2 and below. Both the RAM and Swap
are going to be maxed or near maxed pretty much all the time.

If you want to go with the CLI display method, no actual GUI will be installed, and
instead the text-based Lynx web browser will load the monmon status page at boot."
echo ""
read -p "Enter the external HDMI display method (none/cli/gui): " startup_type_input
startup_type=${startup_type_input,,} # Lower-case the startup type input
if [[ $startup_type != 'cli' && $startup_type != 'gui' ]]
then
  startup_type=none
fi
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
echo "# Run Ansible playbook to deploy monmon to Raspberry Pi"
echo ""
echo "Ansible will ask for the pi user's current password on your Raspberry Pi (SSH
password), and then for an optional new password for the pi user. Leave the new password
blank to keep the current one. Neither password is saved anywhere on this system."
echo ""
cd ansible
ansible-playbook --ask-pass -i ./inventory-install ./install.yml -e "{\"monmon_ip_address\": \"$ip_address\", \"installation_type\": \"$startup_type\"}"
cd ..
echo ""
echo ""
echo "Installation complete!

The monmon status page should be available at http://$ip_address

The Monit web UI should be available at http://$ip_address:2812

In about 30 seconds, the screen attached to your Raspberry Pi should briefly turn green.
When this happens, it means that monmon is up-and-running.

If you installed one of the external HDMI display methods, and you see some red text
above, you may need to re-run the install.sh script. When installing one of these
methods, regardless of the Pi version, it sometimes takes so long that the password
escalation times out later on in the Ansible playbook, causing the playbook to fail. It
fails in a safe spot though, and re-running the install script (while entering the same
details as the last time you ran it) will simply pickup where it left off."
echo ""
