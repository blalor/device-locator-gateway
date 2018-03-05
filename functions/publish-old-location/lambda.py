# -*- encoding: utf-8 -*-

## subscribes to the publish topic used by the device-locator function and posts
## to the old endpoint I originally used.

## http://example.com/record_location/?lat={lat}&lon={long}&accuracy={acc}&alt={alt}&alt_accuracy={altacc}&battery={batt}&ip={ip}&timediff={timediff}&device=Camilla


import os
import json
import urllib
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TARGET_ENDPOINT = os.environ["target_endpoint"]


def handler(event, context):
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

        logging.info(message)

        urllib.urlopen(
            "{}/?{}".format(
                TARGET_ENDPOINT,
                urllib.urlencode({
                    "device": message["device_id"],
                    "lat": message["payload"]["lat"],
                    "lon": message["payload"]["lon"],
                    "accuracy": message["payload"]["accuracy"],
                    "alt": message["payload"]["alt"],
                    "alt_accuracy": message["payload"]["alt_accuracy"],
                    "battery": message["payload"]["battery"],
                    "ip": message["payload"]["ip"],
                    "timediff": message["payload"]["timediff"],
                })
            )
        )
