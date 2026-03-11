import sys
import platform
from datetime import datetime, timezone

from aws_lambda_powertools import Logger

logger = Logger()


@logger.inject_lambda_context
def handler(event, context):
    logger.info("Processing request")

    return {
        "statusCode": 200,
        "body": {
            "message": "Hello from Python Lambda!",
            "runtime": sys.version,
            "architecture": platform.machine(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    }
