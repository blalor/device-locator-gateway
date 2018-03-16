# -*- encoding: utf-8 -*-

import os
import boto3
import json

import requests
from datetime import datetime, timedelta
import iso8601
import xml.etree.cElementTree as ET

import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


NAMESPACES = {
    "kml": "http://www.opengis.net/kml/2.2",
}

TOPIC_ARN = os.environ["topic_arn"] ## the SNS topic we're publishing to
FEED_URL = os.environ["feed_url"] ## the URL we're polling
DEVICE_ID = os.environ["device_id"] ## static device id when publishing

## password for the feed; no username is provided
FEED_PASSWORD = os.environ.get("feed_password")


def handler(event, context):
    sns = boto3.resource("sns")

    ## the SNS topic we're publishing to
    topic = sns.Topic(TOPIC_ARN)

    auth = None
    if FEED_PASSWORD:
        auth = (None, FEED_PASSWORD)

    ## https://files.delorme.com/support/inreachwebdocs/KML%20Feeds.pdf
    ## By default only the most recent point is shown.
    resp = requests.get(
        FEED_URL,
        auth=auth,
        params={
            # "d1": "", ## Start date for the query – in UTC time
        },
    )
    resp.raise_for_status()

    root = ET.fromstring(resp.content)
    for point in root.findall(".//kml:Placemark[kml:Point]", NAMESPACES):
        timestamp = iso8601.parse_date(point.find("kml:TimeStamp/kml:when", NAMESPACES).text)
        lon, lat, alt = point.find("kml:Point/kml:coordinates", NAMESPACES).text.split(",")

        ext_data = {}
        ext_exclude = (
            ## these are from the point
            "Latitude",
            "Longitude",
            "Elevation",

            ## these are irrelevant or from the timestamp
            "Time",
            "Time UTC",

            ## just don't care
            "Id",
            "Map Display Name",
            "Name",
        )
        for ext in point.findall("kml:ExtendedData/kml:Data", NAMESPACES):
            key = ext.attrib["name"]
            val = ext.find("kml:value", NAMESPACES).text

            ## these are duplicated from the coordinates
            if key not in ext_exclude and val:
                ext_data[key] = val

        message = {
            "timestamp":  timestamp.isoformat(),
            "device_id":  DEVICE_ID,
            "request_id": event["id"], ## irrelevant
            "source":     "inreach",

            "position": {
                "lat": lat,
                "lon": lon,
                "alt": alt,
            },

            "meta": ext_data,
        }

        logger.info("publishing message: {}".format(message))

        ## publish to the topic
        resp = topic.publish(Message=json.dumps(message))

        ## abort if the message wasn't accepted
        assert "MessageId" in resp


if __name__ == "__main__":
    main()
