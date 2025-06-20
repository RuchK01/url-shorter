# redirect.py
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambdsa_handler(event, context):
    code = event['pathParameters']['code']
    
    response = table.get_item(Key={'code': code})
    if 'Item' not in response:
        return {'statusCode': 404, 'body': 'Not found'}
    
    url = response['Item']['url']
    return {
        'statusCode': 301,
        'headers': {'Location': url}
    }
