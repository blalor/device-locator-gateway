# -*- encoding: utf-8 -*-

## subscribes to the publish topic used by the device-locator function and
## stores the location and current weather data in dynamodb.

import os
import boto3
import json
import logging
import iso8601
import datetime
from decimal import Decimal
import requests
import util

logger = logging.getLogger()
logger.setLevel(logging.INFO)

EPOCH = datetime.datetime(1970, 1, 1, tzinfo=iso8601.UTC)

TABLE_NAME = os.environ["table_name"]
DARK_SKY_API_KEY = os.environ["dark_sky_api_key"]
OPENCAGE_API_KEY = os.environ["opencage_api_key"]


# https://darksky.net/dev/docs#time-machine-request
# GET https://api.darksky.net/forecast/0123456789abcdef9876543210fedcba/42.3601,-71.0589,255657600?exclude=currently,flags
def dark_sky(lat, lon, time):
    url = "https://api.darksky.net/forecast/{key}/{lat},{lon},{time}".format(
        key=DARK_SKY_API_KEY,
        lat=lat,
        lon=lon,
        time=time.replace(microsecond=0).isoformat(),
    )
    resp = requests.get(
        url,
        params={
            "lang": "en",
            "units": "si",
            "exclude": "minutely,hourly,daily,flags"
        })

    resp.raise_for_status()

    return resp.json()


def opencage(lat, lon):
    kept_annotations = set(("flag", "geohash", "sun", "timezone"))

    url = "https://api.opencagedata.com/geocode/v1/json"
    resp = requests.get(
        url,
        params={
            "key": OPENCAGE_API_KEY,
            "q": "{lat},{lon}".format(lat=lat, lon=lon),
            "no_record": 1,
        }
    )

    resp.raise_for_status()

    results = resp.json()["results"]
    for r in results:
        ## strip out unwanted annotations
        discarded_annotations = set(r["annotations"].keys()) - kept_annotations
        for d in discarded_annotations:
            del r["annotations"][d]

    return results


def handler(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(TABLE_NAME)

    for rec in event["Records"]:
        assert rec["EventSource"] == "aws:sns"

        message = json.loads(rec["Sns"]["Message"])
        # {
        #     "timestamp": "2018-03-05T13:02:29.946549Z",
        #     "device_id": "__main__",
        #     "request_id": "nothing-to-see-here",
        #     "source":     "device-locator",
        #
        #     "position": {
        #         "lat": "37.540948",
        #         "lon": "-77.433026",
        #         "alt": "0",
        #     },
        #
        #     "meta": {
        #         "battery":      "99",
        #         "ip":           "127.0.0.1",
        #         "accuracy":     "-1",
        #         "alt_accuracy": "23",
        #         "timediff":     "-42",
        #     },
        # }

        logger.info(
            "received %s message %s for device %s via subscription %s",
            message["source"],
            message["request_id"],
            message["device_id"],
            rec["EventSubscriptionArn"],
        )

        timestamp = iso8601.parse_date(message["timestamp"])
        device_id = message["device_id"]
        source    = message["source"]

        latitude  = Decimal(message["position"]["lat"])
        longitude = Decimal(message["position"]["lon"])
        altitude  = Decimal(message["position"]["alt"])

        if source == "device-locator":
            timediff = float(message["meta"]["timediff"]) # always negative
            timestamp = timestamp + datetime.timedelta(seconds=timediff)

        item_key = {
            "device_id": device_id, # partition key
            "timestamp": Decimal((timestamp - EPOCH).total_seconds()), # sort key
        }

        ## check to see if the item already exists; the inreach-poller will emit
        ## old events
        do_put = False
        item = table.get_item(Key=item_key).get("Item")
        if item:
            logger.info("found existing item with key ", item_key)
        else:
            item = {
                ## primary key
                "device_id": item_key["device_id"],
                "timestamp": item_key["timestamp"],

                "source": source,

                "latitude":  latitude,
                "longitude": longitude,
                "altitude":  altitude,

                "meta": message["meta"],
            }
            do_put = True

        if "wx" not in item:
            try:
                item["wx"] = dark_sky(latitude, longitude, timestamp)
                item["wx"] = util.replace_floats(item["wx"])
                do_put = True

            except Exception:
                logger.exception("unable to retrieve data from Dark Sky")

        if "opencage" not in item:
            try:
                item["opencage"] = opencage(latitude, longitude)
                item["opencage"] = util.replace_floats(item["opencage"])
                do_put = True

            except Exception:
                logger.exception("unable to retrieve data from OpenCage")

        if do_put:
            table.put_item(Item=item)
        else:
            logger.info("no updates to item")


def main():
    logging.basicConfig()

    handler(
        {
            "Records": [
                {
                    "EventVersion": "1.0",
                    "EventSource": "aws:sns",
                    "EventSubscriptionArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator:0a5e6f92-36ee-4c24-b79f-ee6f57961dc3",
                    "Sns": {
                        "MessageId": "7901a01d-6fa9-51a2-86f5-f30bc269630c",
                        "Signature": "…",
                        "Type": "Notification",
                        "TopicArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator",
                        "MessageAttributes": {},
                        "SignatureVersion": "1",
                        "Timestamp": "2018-03-05T02:29:20.471Z",
                        "SigningCertUrl": "…",
                        "Message": json.dumps({
                            "timestamp": "2018-03-05T13:02:29.946549Z",
                            "device_id": "__main__",
                            "request_id": "nothing-to-see-here",
                            "source":     "device-locator",

                            "position": {
                                "lat": "37.540948",
                                "lon": "-77.433026",
                                "alt": "0",
                            },

                            "meta": {
                                "battery":      "99",
                                "ip":           "127.0.0.1",
                                "accuracy":     "-1",
                                "alt_accuracy": "23",
                                "timediff":     "-42",
                            },
                        }),
                        "UnsubscribeUrl": "…",
                        "Subject": None
                    }
                }
            ],
        },
        None,
    )


if __name__ == "__main__":
    main()
