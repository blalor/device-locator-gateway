# -*- encoding: utf-8 -*-

## https://stackoverflow.com/questions/41429551/aws-gateway-api-base64decode-produces-garbled-binary/41434295#41434295
## https://stackoverflow.com/questions/35804042/aws-api-gateway-and-lambda-to-return-image

import os
import boto3
from boto3.dynamodb.conditions import Key

import time
import pytz
from datetime import datetime, timedelta
from decimal import Decimal
import xml.etree.cElementTree as ET
from StringIO import StringIO
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

GPX_NS = "http://www.topografix.com/GPX/1/1"
UTC = pytz.utc
TABLE_NAME = os.environ["table_name"]


def pretty_format(loc):
    wx_str = ""
    loc_str = ""
    tz_str = loc.get("wx", {"timezone": "UTC"})["timezone"]

    #  u'wx': {u'currently': {u'apparentTemperature': Decimal('2.65'),
    #                         u'cloudCover': Decimal('0.89'),
    #                         u'dewPoint': Decimal('-2.43'),
    #                         u'humidity': Decimal('0.63'),
    #                         u'icon': u'partly-cloudy-night',
    #                         u'ozone': Decimal('400.42'),
    #                         u'precipIntensity': Decimal('0'),
    #                         u'precipProbability': Decimal('0'),
    #                         u'pressure': Decimal('1017.78'),
    #                         u'summary': u'Mostly Cloudy',
    #                         u'temperature': Decimal('4.07'),
    #                         u'time': Decimal('1520824870'),
    #                         u'uvIndex': Decimal('0'),
    #                         u'visibility': Decimal('13.66'),
    #                         u'windBearing': Decimal('79'),
    #                         u'windGust': Decimal('2.73'),
    #                         u'windSpeed': Decimal('1.69')},
    #          u'latitude': Decimal('37.5740038414'),
    #          u'longitude': Decimal('-77.4896974091'),
    #          u'offset': Decimal('-4'),
    #          u'timezone': u'America/New_York'}}
    currently = loc.get("wx", {}).get("currently")
    if currently:
        wx_str = u"%s and %.0f°F" % (
            currently["summary"],
            currently["temperature"] * Decimal(1.8) + 32,
        )

    #  u'opencage': [{u'annotations': {u'flag': u'\U0001f1fa\U0001f1f8',
    #                                  u'geohash': u'dq8vu8jsqc64sgre62fg',
    #                                  u'sun': {u'rise': {u'apparent': Decimal('1520853840'),
    #                                                     u'astronomical': Decimal('1520848620'),
    #                                                     u'civil': Decimal('1520852220'),
    #                                                     u'nautical': Decimal('1520850420')},
    #                                           u'set': {u'apparent': Decimal('1520896440'),
    #                                                    u'astronomical': Decimal('1520815260'),
    #                                                    u'civil': Decimal('1520898000'),
    #                                                    u'nautical': Decimal('1520813460')}},
    #                                  u'timezone': {u'name': u'America/New_York',
    #                                                u'now_in_dst': Decimal('1'),
    #                                                u'offset_sec': Decimal('-14400'),
    #                                                u'offset_string': Decimal('-400'),
    #                                                u'short_name': u'EDT'}},
    #                 u'bounds': {u'northeast': {u'lat': Decimal('37.5740789'),
    #                                            u'lng': Decimal('-77.4896129')},
    #                             u'southwest': {u'lat': Decimal('37.5738789'),
    #                                            u'lng': Decimal('-77.4898129')}},
    #                 u'components': {u'ISO_3166-1_alpha-2': u'US',
    #                                 u'_type': u'building',
    #                                 u'city': u'Richmond City',
    #                                 u'country': u'United States of America',
    #                                 u'country_code': u'us',
    #                                 u'house_number': u'4459',
    #                                 u'postcode': u'23230',
    #                                 u'road': u'Cutshaw Avenue',
    #                                 u'state': u'Virginia',
    #                                 u'state_code': u'VA',
    #                                 u'suburb': u"Scott's Addition"},
    #                 u'confidence': Decimal('10'),
    #                 u'formatted': u'4459 Cutshaw Avenue, Richmond City, VA 23230, United States of America',
    #                 u'geometry': {u'lat': Decimal('37.5739789'),
    #                               u'lng': Decimal('-77.4897129')}}],
    if loc.get("opencage"):
        oc = loc["opencage"][0]

        if "annotations" in oc and "timezone" in oc["annotations"]:
            tz_str = oc["annotations"]["timezone"]["name"]

        locality_keys = ("city", "village", "hamlet", "locality", "town")
        locality = [v for k, v in oc["components"].items() if k in locality_keys]
        if locality:
            locality = locality[0]
        else:
            locality = oc["components"].get("county")
            if not locality:
                locality = "¯\_(ツ)_/¯"

        state = oc["components"].get("state")
        flag = oc.get("annotations", {}).get("flag", u"❓")

        loc_str = u"in %s, %s %s" % (locality, state, flag)

    tz = UTC
    try:
        tz = pytz.timezone(tz_str)
    except pytz.exceptions.UnknownTimeZoneError:
        pass

    time_str = loc["timestamp"].astimezone(tz).strftime("%-I:%M%p").lower()

    result = []
    if wx_str:
        result.append(wx_str)

    result.append("at " + time_str)

    if loc_str:
        result.append(loc_str)

    return " ".join(result)


def handler(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(TABLE_NAME)

    after = time.time() - (24 * 3600) ## one day

    device_id_cond = Key("device_id").eq(event["pathParameters"]["device_id"])
    ts_range_cond = Key("timestamp").gte(Decimal(after))

    location_items = table.query(
        KeyConditionExpression=device_id_cond & ts_range_cond,
    )["Items"]

    root = ET.Element("gpx")
    root.attrib["xmlns"] = GPX_NS
    root.attrib["version"] = "1.1"
    root.attrib["creator"] = "device-locator"

    ET.SubElement(
        ET.SubElement(root, "metadata"),
        "time"
    ).text = datetime.utcnow().isoformat() + "Z"

    # {u'altitude': Decimal('69'),
    #  u'device_id': u'Dummy',
    #  u'latitude': Decimal('37.540948'),
    #  u'longitude': Decimal('-77.433026'),
    #  u'meta': {u'accuracy': u'0',
    #            u'alt_accuracy': u'1',
    #            u'battery': u'0',
    #            u'ip': u'127.0.0.1',
    #            u'timediff': u'-42'},
    #  u'opencage': [{u'annotations': {u'flag': u'\U0001f1fa\U0001f1f8',
    #                                  u'geohash': u'dq8vtfph15rmfb9fv7fy',
    #                                  u'sun': {u'rise': {u'apparent': Decimal('1521285360'),
    #                                                     u'astronomical': Decimal('1521280140'),
    #                                                     u'civil': Decimal('1521283800'),
    #                                                     u'nautical': Decimal('1521281940')},
    #                                           u'set': {u'apparent': Decimal('1521328740'),
    #                                                    u'astronomical': Decimal('1521247560'),
    #                                                    u'civil': Decimal('1521330300'),
    #                                                    u'nautical': Decimal('1521245700')}},
    #                                  u'timezone': {u'name': u'America/New_York',
    #                                                u'now_in_dst': Decimal('1'),
    #                                                u'offset_sec': Decimal('-14400'),
    #                                                u'offset_string': Decimal('-400'),
    #                                                u'short_name': u'EDT'}},
    #                 u'bounds': {u'northeast': {u'lat': Decimal('37.5414335'),
    #                                            u'lng': Decimal('-77.4324167')},
    #                             u'southwest': {u'lat': Decimal('37.540543'),
    #                                            u'lng': Decimal('-77.4335056')}},
    #                 u'components': {u'ISO_3166-1_alpha-2': u'US',
    #                                 u'_type': u'townhall',
    #                                 u'city': u'Richmond City',
    #                                 u'country': u'United States of America',
    #                                 u'country_code': u'us',
    #                                 u'house_number': u'900',
    #                                 u'postcode': u'23223',
    #                                 u'road': u'East Broad Street',
    #                                 u'state': u'Virginia',
    #                                 u'state_code': u'VA',
    #                                 u'suburb': u'Shockoe Slip',
    #                                 u'townhall': u'Richmond City Hall'},
    #                 u'confidence': Decimal('9'),
    #                 u'formatted': u'Richmond City Hall, 900 East Broad Street, Richmond City, VA 23223, United States of America',
    #                 u'geometry': {u'lat': Decimal('37.5409882'),
    #                               u'lng': Decimal('-77.4329612')}}],
    #  u'source': u'device-locator',
    #  u'timestamp': Decimal('1521288169.467999935150146484375'),
    #  u'wx': {u'currently': {u'apparentTemperature': Decimal('-2.13'),
    #                         u'cloudCover': Decimal('0.13'),
    #                         u'dewPoint': Decimal('-6.67'),
    #                         u'humidity': Decimal('0.71'),
    #                         u'icon': u'clear-day',
    #                         u'ozone': Decimal('368.09'),
    #                         u'precipIntensity': Decimal('0'),
    #                         u'precipProbability': Decimal('0'),
    #                         u'pressure': Decimal('1018'),
    #                         u'summary': u'Clear',
    #                         u'temperature': Decimal('-2.13'),
    #                         u'time': Decimal('1521288169'),
    #                         u'uvIndex': Decimal('0'),
    #                         u'visibility': Decimal('13.37'),
    #                         u'windBearing': Decimal('198'),
    #                         u'windGust': Decimal('2.36'),
    #                         u'windSpeed': Decimal('1.1')},
    #          u'latitude': Decimal('37.540948'),
    #          u'longitude': Decimal('-77.433026'),
    #          u'offset': Decimal('-4'),
    #          u'timezone': u'America/New_York'}}
    for l in location_items:
        l["timestamp"] = datetime.utcfromtimestamp(l["timestamp"]).replace(tzinfo=UTC)

    if location_items:
        wpt = location_items[-1]

        wpt_elt = ET.SubElement(root, "wpt")
        wpt_elt.attrib["lat"] = str(wpt["latitude"])
        wpt_elt.attrib["lon"] = str(wpt["longitude"])

        ET.SubElement(wpt_elt, "time").text = wpt["timestamp"].isoformat()
        ET.SubElement(wpt_elt, "name").text = "Current location"
        ET.SubElement(wpt_elt, "desc").text = pretty_format(wpt)

        trk_elt = ET.SubElement(root, "trk")
        trkseg_elt = ET.SubElement(trk_elt, "trkseg")

        last_ts = location_items[0]["timestamp"]
        for loc_item in location_items:
            ts = loc_item["timestamp"]
            if ts - last_ts > timedelta(minutes=30):
                ## start a new trkseg
                trkseg_elt = ET.SubElement(trk_elt, "trkseg")

            last_ts = ts

            trkpt_elt = ET.SubElement(trkseg_elt, "trkpt")
            trkpt_elt.attrib["lat"] = str(loc_item["latitude"])
            trkpt_elt.attrib["lon"] = str(loc_item["longitude"])
            ET.SubElement(trkpt_elt, "time").text = ts.isoformat() + "Z"
            ET.SubElement(trkpt_elt, "ele").text = str(loc_item["altitude"])

            ET.SubElement(trkpt_elt, "desc").text = pretty_format(loc_item)

    gpx_output = StringIO()
    ET.ElementTree(root).write(gpx_output, encoding="UTF-8")

    ## return an appropriate response to the API Gateway
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/gpx+xml; charset=utf-8",
        },
        "body": gpx_output.getvalue(),
    }


def main():
    handler(
        {
            "pathParameters": {
                "device_id": "Camilla",
            },
        },
        None,
    )


if __name__ == "__main__":
    main()
