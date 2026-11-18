import logging
import os
import socket

import boto3


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
CLOUDWATCH = boto3.client("cloudwatch")


def _can_connect(probe_ip):
    try:
        with socket.create_connection((probe_ip, 443), timeout=3):
            return True
    except OSError as error:
        LOGGER.warning("NAT egress probe to %s failed: %s", probe_ip, error)
        return False


def lambda_handler(_event, _context):
    nat_name = os.environ["NAT_NAME"]
    probe_ips = os.environ["PROBE_IPS"].split(",")
    probe_results = {probe_ip: _can_connect(probe_ip) for probe_ip in probe_ips}
    healthy = int(any(probe_results.values()))

    CLOUDWATCH.put_metric_data(
        Namespace="MGPZZ/NAT",
        MetricData=[
            {
                "MetricName": "EgressHealthy",
                "Dimensions": [{"Name": "NatName", "Value": nat_name}],
                "Value": healthy,
                "Unit": "Count",
            }
        ],
    )

    LOGGER.info("NAT egress result for %s: %s", nat_name, probe_results)
    return {"nat_name": nat_name, "healthy": healthy, "probes": probe_results}
