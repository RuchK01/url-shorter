# redirect.py
import boto3
import os


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])


def lambda_handler(event, context): # E302: Ensured exactly two blank lines above this definition.
    # W293: This blank line must contain NO whitespace (delete any spaces/tabs here).
    code = event['pathParameters']['code']

    response = table.get_item(Key={'code': code})
    if 'Item' not in response:
        return {'statusCode': 404, 'body': 'Not found'}

    # W293: This blank line must contain NO whitespace (delete any spaces/tabs here).
    url = response['Item']['url']
    return {
        'statusCode': 301,
        'headers': {'Location': url}
    }
# W292: Added a newline at the very end of the file.