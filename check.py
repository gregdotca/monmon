#!/usr/bin/env python3
"""
Author: Greg Chetcuti <greg@chetcuti.com>
Date: 2022-06-12
Purpose: monmon node check script (check.py)
"""

import argparse
import json
import os.path
import requests
import xmltodict
from requests.auth import HTTPBasicAuth

# Global variables
alert_report = []
alerts_filename = "alerts"
# Tells alert.py that a check has run since the Pi booted (/run is emptied at every boot)
checked_filename = "/run/monmon-checked"
alert_off_include_filename = "include.alert_off"
alert_on_include_filename = "include.alert_on"

# UptimeRobot URLs
UPR_DASHBOARD_URL = "https://uptimerobot.com/dashboard#mainDashboard"
UPR_URL = "https://api.uptimerobot.com/v2/getAccountDetails"


# =============================================================================
# Main                                                                     Main
# ----------------------------------------------------------
def main():
    """Run the main program"""
    global alert_report
    global alerts_filename
    global alert_off_include_filename
    global alert_on_include_filename

    args = get_args()
    alert_report = []

    for node in args.nodes:

        # If it's a Healthchecks.io node (hch)
        if node[0] == "hch":

            # type node[0]  label node[1]  base healthchecks.io url node[2]
            # api key node[3]
            process_api_hch(node[0], node[1], node[2], node[3])

        # If it's a Monit node (mnt)
        elif node[0] == "mnt":

            # type node[0]  label node[1]  base monit url node[2]
            # monit ui username node[3]  monit ui password node[4]
            process_api_mnt(node[0], node[1], node[2], node[3], node[4])

        # If it's an Uptime Kuma node (upk)
        elif node[0] == "upk":

            # type node[0]  label node[1]  uptime kuma url node[2]
            # uptime kuma ui username node[3]  uptime kuma ui password node[4]
            process_api_upk(node[0], node[1], node[2], node[3], node[4])

        # If it's an UptimeRobot node (upr)
        elif node[0] == "upr":

            # type node[0]  label node[1]  api key node[2]
            process_api_upr(node[0], node[1], node[2])

        else:

            alert_report.append(alert_text(node[0], "Invalid Node Type", ""))
            return

    if not alert_report:

        delete_alerts()
        mark_checked()
        alert_off_includes()

    else:

        write_alerts()
        mark_checked()
        alert_on_includes()


# =============================================================================
# Arguments                                                           Arguments
# ----------------------------------------------------------
def get_args():
    """Get the command-line arguments"""
    parser = argparse.ArgumentParser(
        description="Check the monmon nodes for issues",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-n",
        "--nodes",
        default="nodes.custom" if os.path.isfile("nodes.custom") else "nodes",
        help="Node file (nodes.custom if it exists, otherwise nodes)",
        metavar="nodes",
        type=str,
    )

    args = parser.parse_args()

    node_list = []
    if os.path.isfile(args.nodes):
        with open(args.nodes) as node_rows:
            node_list = node_rows.readlines()

    # Remove blank lines
    clean_node_list = [n for n in node_list if n != "\n"]

    list_of_pieces = []
    args.nodes = []
    for node_row in clean_node_list:
        if not node_row[0].startswith("#"):
            list_of_pieces.append(node_row.rstrip().split(":::::"))

    args.nodes = list_of_pieces

    return args


# =============================================================================
# Functions                                                           Functions
# ----------------------------------------------------------
def alert_text(monitor_type, label, url):
    return (
        '<span style="color: red;" class="blinking">ALERT</span>&nbsp;&nbsp;&nbsp;'
        + '<a href="'
        + url
        + '">'
        + label
        + "&nbsp;&nbsp;&nbsp;"
        + monitor_type
        + "</a>&nbsp;&nbsp;&nbsp;<span"
        + 'style="color: red;" class="blinking">ALERT</span><BR>'
    )


def process_api_hch(monitor_type, label, url, api_key):

    try:

        headers = {"X-Api-Key": api_key}
        full_api_url = url + "/api/v1/checks/"
        response = requests.get(full_api_url, headers=headers)
        response.encoding = "utf-8"
        result = json.loads(response.text)

        # If the API call fails, alert
        if response.status_code != 200:
            alert_report.append(alert_text(monitor_type, label, url))
            return

        # If no checks are found, alert
        if not result["checks"]:
            alert_report.append(alert_text(monitor_type, label, url))
            return

        # Cycle through the checks
        else:

            for check in result["checks"]:

                # If a check is down, alert
                if "down" in check["status"]:
                    alert_report.append(alert_text(monitor_type, label, url))
                    return

    except:

        alert_report.append(alert_text(monitor_type, label, url))
        return

    return


def process_api_mnt(monitor_type, label, url, username, password):

    try:

        full_url = url + "/_status?format=xml"
        response = requests.get(full_url, auth=HTTPBasicAuth(username, password))
        response.encoding = "utf-8"
        result_dict = dict(xmltodict.parse(response.text))
        services = json.dumps(result_dict["monit"]["service"])

        # If the API call fails, alert
        if response.status_code != 200:
            alert_report.append(alert_text(monitor_type, label, url))
            return

        # Determine the total number of statuses returned, as well as how many of them
        # were successful
        status_count_total = services.count('"status": "')
        status_count_success = services.count('"status": "0"')

        # Compare the above status counts and if they aren't equal, alert
        if status_count_total != status_count_success:
            alert_report.append(alert_text(monitor_type, label, url))
            return

    except:

        alert_report.append(alert_text(monitor_type, label, url))
        return

    return


def process_api_upk(monitor_type, label, url, username, password):

    try:

        result = requests.get(url + "/metrics", auth=(username, password))

        for line in result.text.split("\n"):
            if line.startswith("monitor_status") and line.endswith("0"):
                alert_report.append(alert_text(monitor_type, label, url))
                return

    except:

        alert_report.append(alert_text(monitor_type, label, url))
        return

    return


def process_api_upr(monitor_type, label, api_key):

    try:

        headers = {
            "cache-control": "no-cache",
            "content-type": "application/x-www-form-urlencoded",
        }
        data = {"api_key": api_key, "format": "json"}
        response = requests.post(UPR_URL, headers=headers, data=data)
        response.encoding = "utf-8"
        result = json.loads(response.text)

        # If the API call fails, alert
        if response.status_code != 200:
            alert_report.append(alert_text(monitor_type, label, UPR_DASHBOARD_URL))
            return

        # If there are down monitors, alert
        if result["account"]["down_monitors"] != 0:
            alert_report.append(alert_text(monitor_type, label, UPR_DASHBOARD_URL))
            return

    except:

        alert_report.append(alert_text(monitor_type, label, UPR_DASHBOARD_URL))
        return

    return


def write_alerts():

    try:

        alerts_file = open(alerts_filename, "w")

        for each in alert_report:
            alerts_file.write(each)

        alerts_file.close()

    except:

        print("ERROR :: Unable to write to the alerts file")
        exit()

    return


def delete_alerts():

    try:

        if os.path.isfile(alerts_filename):

            os.unlink(alerts_filename)

    except:

        print("ERROR :: Unable to delete the alerts file")
        exit()

    return


def mark_checked():

    try:

        open(checked_filename, "w").close()

    except:

        print("ERROR :: Unable to write the checked file")

    return


def alert_off_includes():

    if os.path.isfile(alert_off_include_filename):
        os.system("/usr/bin/python " + alert_off_include_filename)

    return


def alert_on_includes():

    if os.path.isfile(alert_on_include_filename):
        os.system("/usr/bin/python " + alert_on_include_filename)

    return


# ----------------------------------------------------------
if __name__ == "__main__":
    main()
