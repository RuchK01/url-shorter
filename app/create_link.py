import json
import boto3
import os
import random
import string


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


def lambda_handler(event, context):
    body = json.loads(event['body'])
    original_url = body['url']
    short_code = ''.join(random.choices(
        string.ascii_letters + string.digits,  # E222: Ensured exactly one space around '+'
        k=6
    ))

    table.put_item(Item={
        'code': short_code,
        'url': original_url
    })

    return {
        'statusCode': 200,
        'body': json.dumps(
            {   # E122: Indented this opening brace correctly relative to `json.dumps(`.
                'short_url':
                    f"{event['requestContext']['domainName']}/{short_code}" # E128: Indented 4 spaces further than 'short_url:'.
            }
        )
    }
# W292: Added a newline at the very end of the file.