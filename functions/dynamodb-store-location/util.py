# -*- encoding: utf-8 -*-

## inspired by https://github.com/boto/boto3/issues/369#issuecomment-157205696

from decimal import Decimal


def replace_floats(obj):
    if isinstance(obj, list):
        for i in xrange(len(obj)):
            obj[i] = replace_floats(obj[i])

        return obj

    elif isinstance(obj, dict):
        for k in obj.iterkeys():
            obj[k] = replace_floats(obj[k])

        return obj

    elif isinstance(obj, float):
        ## https://github.com/boto/boto3/issues/665
        ## (╯°□°）╯︵ ┻━┻
        return Decimal(str(obj))

    else:
        return obj
