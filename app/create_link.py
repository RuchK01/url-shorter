    import json
    import boto3
    import os
    import random
    import string
    from aws_lambda_powertools import Logger
    from aws_lambda_powertools.event_handler import APIGatewayRestResolver
    from aws_lambda_powertools.utilities.typing import LambdaContext


    logger = Logger(service="url-shortener-create")
    resolver = APIGatewayRestResolver()

    # Initialize DynamoDB client outside the handler for better performance
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])


    @resolver.post("/create") # Endpoint to create a short link
    @logger.inject_lambda_context # Inject context for logging
    @logger.log_metrics # Log metrics for monitoring
    def create_link_handler(event: dict, context: LambdaContext):
        """
        Handles the POST request to create a short link.
        Extracts the original URL from the request body, generates a short code,
        stores it in DynamoDB, and returns the shortened URL.
        """
        body = resolver.current_event.json_body
        original_url = body['url']

        logger.info("Received request to shorten URL", url=original_url)

        short_code = ''.join(random.choices(
            string.ascii_letters + string.digits, k=6
        ))

        # Store the short code and original URL in DynamoDB
        table.put_item(Item={
            'code': short_code,
            'url': original_url
        })

        # Construct the full shortened URL using the API Gateway domain
        api_domain = event['requestContext']['domainName']
        short_url = f"https://{api_domain}/{short_code}"

        logger.info(
            "URL shortened successfully", short_code=short_code, short_url=short_url
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'short_url': short_url})
        }


    # This is the main entry point for AWS Lambda.
    # It delegates to the APIGatewayRestResolver.
    def lambda_handler(event: dict, context: LambdaContext):
        """
        AWS Lambda entry point for the create link function.
        Delegates event processing to the APIGatewayRestResolver.
        """
        return resolver.resolve(event, context)
    