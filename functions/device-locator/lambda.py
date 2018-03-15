# -*- encoding: utf-8 -*-

# this is a lambda function that handles requests like
#    /record_location/Camilla?lat={lat}&lon={long}&accuracy={acc}&alt={alt}&alt_accuracy={altacc}&battery={batt}&ip={ip}&timediff={timediff}
# and publishes a payload to an SNS topic.

import logging
import datetime
import json
import os
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    ## event:
    # {
    #     "body": null,
    #     "resource": "/record_location/{device_id+}",
    #     "requestContext": {
    #         "requestTime": "05/Mar/2018:03:10:54 +0000",
    #         "protocol": "HTTP/1.1",
    #         "resourceId": "84wfaw",
    #         "apiId": "54f0rg5tk0",
    #         "resourcePath": "/record_location/{device_id+}",
    #         "httpMethod": "GET",
    #         "requestId": "d126d53d-2022-11e8-9ed6-a30b73d7c377",
    #         "path": "/prod/record_location/Camilla",
    #         "accountId": "abcdef012345",
    #         "requestTimeEpoch": 1520219454476,
    #         "identity": {
    #             "userArn": null,
    #             "cognitoAuthenticationType": null,
    #             "accessKey": null,
    #             "caller": null,
    #             "userAgent": "curl/7.54.0",
    #             "user": null,
    #             "cognitoIdentityPoolId": null,
    #             "cognitoIdentityId": null,
    #             "cognitoAuthenticationProvider": null,
    #             "sourceIp": "127.0.0.1",
    #             "accountId": null
    #         },
    #         "stage": "prod"
    #     },
    #     "queryStringParameters": {
    #         "battery": "0",
    #         "ip": "127.0.0.1",
    #         "lon": "-99",
    #         "alt_accuracy": "1",
    #         "lat": "99",
    #         "timediff": "-42",
    #         "alt": "69",
    #         "accuracy": "0"
    #     },
    #     "httpMethod": "GET",
    #     "pathParameters": {
    #         "device_id": "Camilla"
    #     },
    #     "headers": {
    #         "Via": "2.0 3f717e4fd5cbd6c94c4a3860328e1093.cloudfront.net (CloudFront)",
    #         "CloudFront-Is-Desktop-Viewer": "true",
    #         "CloudFront-Is-SmartTV-Viewer": "false",
    #         "CloudFront-Forwarded-Proto": "https",
    #         "X-Forwarded-For": "127.0.0.1, 127.0.0.1",
    #         "CloudFront-Viewer-Country": "US",
    #         "Accept": "*/*",
    #         "User-Agent": "curl/7.54.0",
    #         "X-Amzn-Trace-Id": "Root=1-5a9cb53e-9fd5a9f0115beb6d57ecf7a8",
    #         "Host": "deadbeef.execute-api.us-east-1.amazonaws.com",
    #         "X-Forwarded-Proto": "https",
    #         "X-Amz-Cf-Id": "2p8iR__27vNbp7mCqtfkWWTzMLYSxQDeA30d9xen1OjLU3WV8Olfuw==",
    #         "CloudFront-Is-Tablet-Viewer": "false",
    #         "X-Forwarded-Port": "443",
    #         "CloudFront-Is-Mobile-Viewer": "false"
    #     },
    #     "stageVariables": null,
    #     "path": "/record_location/Camilla",
    #     "isBase64Encoded": false
    # }
    sns = boto3.resource("sns")

    ## the SNS topic we're publishing to
    topic = sns.Topic(os.environ["topic_arn"])

    timestamp = datetime.datetime.utcfromtimestamp(
        float(event["requestContext"]["requestTimeEpoch"]) / 1000
    ).isoformat() + "Z"

    message = {
        "timestamp":  timestamp,
        "device_id":  event["pathParameters"]["device_id"],
        "request_id": event["requestContext"]["requestId"],
        "source":     "device-locator",

        "position": {
            "lat": event["queryStringParameters"]["lat"],
            "lon": event["queryStringParameters"]["lon"],
            "alt": event["queryStringParameters"]["alt"],
        },
        "meta": event["queryStringParameters"],
    }

    for pos_key in ("lat", "lon", "alt"):
        del message["meta"][pos_key]

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
