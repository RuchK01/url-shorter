    import boto3
    import os
    import json # Although not explicitly used by the resolver here, useful for common Lambda patterns.
    from aws_lambda_powertools import Logger
    from aws_lambda_powertools.event_handler import APIGatewayRestResolver
    from aws_lambda_powertools.utilities.typing import LambdaContext


    logger = Logger(service="url-shortener-redirect")
    resolver = APIGatewayRestResolver()

    # Initialize DynamoDB client outside the handler for better performance
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['TABLE_NAME'])


    @resolver.get("/{code}")
    @logger.inject_lambda_context # Keep this first for context injection
    @logger.log_metrics # Placed after inject_lambda_context
    def redirect_handler(event: dict, context: LambdaContext):
        """
        Handles the GET request to redirect from a short code to the original URL.
        Retrieves the short code from path parameters, fetches the original URL
        from DynamoDB, and returns a 301 redirect response.
        """
        code = resolver.current_event.path_parameters.get('code')

        logger.info("Received request to redirect short code", short_code=code)

        if not code:
            logger.error("Missing short code in path parameters")
            return {'statusCode': 400, 'body': 'Bad Request: Missing short code'}

        response = table.get_item(Key={'code': code})
        if 'Item' not in response:
            logger.warning("Short code not found", short_code=code)
            return {'statusCode': 404, 'body': 'Not Found'}

        url = response['Item']['url']
        logger.info("Redirecting to original URL", short_code=code, original_url=url)

        return {
            'statusCode': 301,
            'headers': {'Location': url}
        }


    # This is the main entry point for AWS Lambda.
    # It delegates to the APIGatewayRestResolver.
    def lambda_handler(event: dict, context: LambdaContext):
        """
        AWS Lambda entry point for the redirect function.
        Includes a debug option to force an error for CloudWatch alarm testing.
        Delegates event processing to the APIGatewayRestResolver.
        """
        # This part can be used to inject custom error for testing CloudWatch alarm
        if event.get('queryStringParameters', {}).get('force_error') == 'true':
            logger.error("Forcing a 500 error for alarm testing!")
            return {
                'statusCode': 500,
                'body': 'Forced Internal Server Error for testing CloudWatch alarm.'
            }
        return resolver.resolve(event, context)
    