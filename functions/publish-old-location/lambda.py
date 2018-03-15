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

        logger.info("received message from {} via subscription {}".format(
            rec["EventSubscriptionArn"],
            message["request_id"],
        ))

        logging.info(message)

        source = message["source"]
        if source != "device-locator":
            logger.warn("ignoring unknown source {}".format(source))
        else:
            urllib.urlopen(
                "{}/?{}".format(
                    TARGET_ENDPOINT,
                    urllib.urlencode({
                        "device":       message["device_id"],
                        "lat":          message["position"]["lat"],
                        "lon":          message["position"]["lon"],
                        "alt":          message["position"]["alt"],
                        "battery":      message["meta"]["battery"],
                        "ip":           message["meta"]["ip"],
                        "accuracy":     message["meta"]["accuracy"],
                        "alt_accuracy": message["meta"]["alt_accuracy"],
                        "timediff":     message["meta"]["timediff"],
                    })
                )
            )
