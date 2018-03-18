This is a set of AWS Lambda functions, AWS API Gateway integrations, and Terraform code that records the location history of your devices.

This project started as a replacement for an old service I'd created to show my current location on a blog during road trips.  I have the [Device Locator](https://itunes.apple.com/us/app/device-locator-track-locate-family-members-lost-or/id380395093?mt=8) app on my iPhone; it sends periodic location updates to a [3rd-party service](https://device-locator.com) which then forwards those updates to this service.  I then extended it to poll a Garmin inReach MapShare KML feed.  I'll probably replace Device Locator with [OwnTracks](https://itunes.apple.com/us/app/mqttitude/id692424691?mt=8) soon.

The recorded points are augmented with weather data from Dark Sky and location from the OpenCage reverse geocoder.  This allows each historical point to show where you were (in a geo-political sense) and what the weather was at that time.  The only endpoint currently returns a GPX document with points for the previous 24 hours.

This thing's organic af, so don't judge me for naming, code structure, etc.  I won't apologize. 🧐

Each device's location updates are stored with a `device_id` that's determined by you in advance.  I use Muppets (Rowlf, Camilla, etc.).  You do you.

## design

I use the word "design" loosely.

`GET /record_location/<device_id>` is handled by the `device-locator` Lambda function.  It publishes messages to an SNS topic.

The `inreach-poller` function is triggered periodically by a Cloudwatch Event.  It polls the inReach feed for 30 minutes of data and publishes each point as a message to the SNS topic.

The `dynamodb-store-location` function is subscribed to the SNS topic.  It adds the weather and geocoding data to the point and stores them in a dynamodb table.  Points are deduplicated by their `(device_id, timestamp)` key.

The `publish-old-location` function is subscribed to the SNS topic.  It makes `GET` requests to the configured endpoint for all points received via `/record_location`; it does not forward points creates by the `inreach-poller`.

`GET /gpx/<device_id>` is handled by the `gpx` Lambda function.

## installation

1. Get an API key for the [OpenCage geocoder](https://geocoder.opencagedata.com); this is free for up to 2,500 requests/day and 1 request/sec.
2. Get an API key for [Dark Sky](https://darksky.net/dev); the trial plan is free for up to 1,000 requests/day
3. If you're using an inReach device, get the MapShare feed URL and password from your account (unauthenticated access is not supported).  Otherwise, delete `terraform/fn-inreach_poller.tf`.
4. If you want to have the Device Locator updates forwarded to another endpoint, get that URL and look at `functions/publish-old-location/lambda.py`; otherwise delete `terraform/fn-publish_old_location.tf`.

Create `terraform/terraform.tfvars` thusly, leaving out the obvious bits if you're not using 'em:

```
dark_sky_api_key = "…"
opencage_api_key = "…"

inreach_feed_url      = "https://inreach.garmin.com/feed/Share/<your-feed-name>"
inreach_feed_password = "<feed password>"
inreach_device_id     = "<device id>"
inreach_poll_rate = "9 minutes"

old_location_target_endpoint = "http://example.com/record_location"
```

`make plan` should present you with a plan of what Terraform will do.  `make apply` will then make it so.  Terraform outputs the base URL of the API gateway.

You can send a test location:

    curl -fS "$( terraform output -state=terraform/terraform.tfstate base_url )/record_location/Dummy?lat=37.540948&lon=-77.433026&accuracy=0&alt=69&alt_accuracy=1&battery=0&ip=127.0.0.1&timediff=-42"

And then get the GPX:

    curl -fS "$( terraform output -state=terraform/terraform.tfstate base_url )/gpx/Dummy"

You can see what data was stored in the dynamodb table:

    aws dynamodb scan --table-name device-locator

## integration

Once you've successfully applied the config, you can now configure your Device Locator [forwarding URL](https://device-locator.com/how_to.php#forwarding).  The supported format is:

    <base_url>/record_location/<device_id>?lat={lat}&lon={long}&accuracy={acc}&alt={alt}&alt_accuracy={altacc}&battery={batt}&ip={ip}&timediff={timediff}

## references

- https://apimeister.com/2017/09/13/integrate-api-gateway-with-sns-using-cloudformation.html
- https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html#api-gateway-proxy-integration-lambda-function-python
- https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html
- https://pypi.python.org/pypi/timezonefinder
- https://github.com/evansiroky/timezone-boundary-builder
- https://files.delorme.com/support/inreachwebdocs/KML%20Feeds.pdf
