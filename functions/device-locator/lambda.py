# -*- encoding: utf-8 -*-

import json
import os
import boto3


def handler(event, context):
    sns = boto3.resource("sns")
    topic = sns.Topic(os.environ["topic_arn"])

    resp = topic.publish(
        Message=json.dumps({
            "device_id": event["pathParameters"]["device_id"],
            "payload": event["queryStringParameters"],
        }),
    )

    assert "MessageId" in resp

    return {
        "statusCode": 202,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps({
            "MessageId": resp["MessageId"]
        }),
    }
