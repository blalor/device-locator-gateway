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


def handler(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(TABLE_NAME)

    # {
    #     "Records": [
    #         {
    #             "EventVersion": "1.0",
    #             "EventSource": "aws:sns",
    #             "EventSubscriptionArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator:0a5e6f92-36ee-4c24-b79f-ee6f57961dc3",
    #             "Sns": {
    #                 "MessageId": "7901a01d-6fa9-51a2-86f5-f30bc269630c",
    #                 "Signature": "J0qUj17NAEw1+4Uf+8EfLefGT7zsLc8ZD3YfYd2by/3/sXvfU4s1WLbDzq0P+Z4UIoffxagngliFXTsgTnz4IHrzyF15uYT/JcJpXfti9TaOoleVedE6mQsjRG2aWC8kduYowCwXzv/d83ewWvMycgZkCFtgyM2W2NHJ1IIHBqzvfIgZDdrT4LkRxNm9+4tGb+BULV7NwV+rlV1rY0UJlmZ2YTkWLg2I0MDJ4GHk+N/rHYo4zw9Ud/0TWqT9kYjNWcInlBxBTlPPcPlz8i7+iUVgIWpkNlOLfG5JDTPLvstl7aZIpT48jJRm3pJb/7xUxf9u20CGzykPBPNy51z13Q==",
    #                 "Type": "Notification",
    #                 "TopicArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator",
    #                 "MessageAttributes": {},
    #                 "SignatureVersion": "1",
    #                 "Timestamp": "2018-03-05T02:29:20.471Z",
    #                 "SigningCertUrl": "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-433026a4050d206028891664da859041.pem",
    #                 "Message": "{\"payload\": {\"qwerty\": \"asdf\", \"baz\": \"bap\"}, \"device_id\": \"Camilla\"}",
    #                 "UnsubscribeUrl": "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:abcdef012345:device-locator:0a5e6f92-36ee-4c24-b79f-ee6f57961dc3",
    #                 "Subject": null
    #             }
    #         }
    #     ]
    # }
    for rec in event["Records"]:
        assert rec["EventSource"] == "aws:sns"

        message = json.loads(rec["Sns"]["Message"])

        logger.info("received message from {} via subscription {}".format(
            rec["EventSubscriptionArn"],
            message["request_id"],
        ))

        # logger.info(message)

        device_id         = message["device_id"]
        timestamp         = iso8601.parse_date(message["timestamp"])
        timediff          = float(message["payload"]["timediff"]) # always negative

        timestamp = timestamp + datetime.timedelta(seconds=timediff)

        latitude          = Decimal(message["payload"]["lat"])
        longitude         = Decimal(message["payload"]["lon"])
        accuracy          = Decimal(message["payload"]["accuracy"])
        altitude          = Decimal(message["payload"]["alt"])
        altitude_accuracy = Decimal(message["payload"]["alt_accuracy"])
        battery           = Decimal(message["payload"]["battery"])
        ip_address        = message["payload"]["ip"]

        item = {
            ## primary key
            "device_id": device_id, # partition key
            "timestamp": Decimal((timestamp - EPOCH).total_seconds()), # sort key

            ## add'l attributes
            "latitude":          latitude,
            "longitude":         longitude,
            "accuracy":          accuracy,
            "altitude":          altitude,
            "altitude_accuracy": altitude_accuracy,
            "battery":           battery,
            "ip_address":        ip_address,
        }

        try:
            item["wx"] = dark_sky(latitude, longitude, timestamp)
            item["wx"] = util.replace_floats(item["wx"])

        except Exception:
            logger.exception("unable to retrieve data from Dark Sky")

        table.put_item(Item=item)


def main():
    handler(
        {
            "Records": [
                {
                    "EventVersion": "1.0",
                    "EventSource": "aws:sns",
                    "EventSubscriptionArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator:0a5e6f92-36ee-4c24-b79f-ee6f57961dc3",
                    "Sns": {
                        "MessageId": "7901a01d-6fa9-51a2-86f5-f30bc269630c",
                        "Signature": "≥",
                        "Type": "Notification",
                        "TopicArn": "arn:aws:sns:us-east-1:abcdef012345:device-locator",
                        "MessageAttributes": {},
                        "SignatureVersion": "1",
                        "Timestamp": "2018-03-05T02:29:20.471Z",
                        "SigningCertUrl": "…",
                        "Message": json.dumps({
                            "request_id": "nothing-to-see-here",
                            "timestamp": "2018-03-05T13:02:29.946549Z",
                            "device_id": "__main__",
                            "payload": {
                                "timediff":     "-42",
                                "lat":          "37.540948",
                                "lon":          "-77.433026",
                                "accuracy":     "-1",
                                "alt":          "0",
                                "alt_accuracy": "23",
                                "battery":      "99",
                                "ip":           "127.0.0.1",
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
