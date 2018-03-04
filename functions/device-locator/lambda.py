# -*- encoding: utf-8 -*-

# this is a lambda function that handles requests like
#    /record_location/Camilla?lat={lat}&lon={long}&accuracy={acc}&alt={alt}&alt_accuracy={altacc}&battery={batt}&ip={ip}&timediff={timediff}
# and publishes a payload to an SNS topic.

import logging
import json
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    sns = boto3.resource("sns")

    ## the SNS topic we're publishing to
    topic = sns.Topic(os.environ["topic_arn"])

    message = {
        "device_id": event["pathParameters"]["device_id"],
        "payload": event["queryStringParameters"],
    }

    logger.info("publishing message: {}".format(message))

    ## publish to the topic
    resp = topic.publish(Message=json.dumps(message))

    ## abort if the message wasn't accepted
    assert "MessageId" in resp

    ## return an appropriate response to the API Gateway
    return {
        "statusCode": 202,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps({
            "MessageId": resp["MessageId"]
        }),
    }
