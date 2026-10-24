# Changelog

## 2026-10-24

- Stop `install.sh` from editing tracked files. It used to write the Pi's IP address and the display method into `ansible/inventory-install`, `ansible/roles/monmon/templates/nodes.j2`, and `ansible/group_vars/all.yml` with `sed`, which left the working tree changed after every install and could get those values committed by mistake. It now passes them to `ansible-playbook` as extra variables (`monmon_ip_address` and `installation_type`), and the inventory and the default Node file read them from there. `installation_type` now defaults to `none` in `group_vars/all.yml`.
- Make `install.sh` check that the Pi's IP address is a valid IPv4 address, asking again until it is, and pass the extra variables to Ansible as JSON, so a mistyped address can't set other Ansible variables or break the command.
- Document in `README.md` how to run the Ansible playbook by hand, with the two extra variables it now needs and the custom configuration files it expects in the `ansible` folder.
