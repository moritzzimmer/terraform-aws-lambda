# code migrated from https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#reference-appspec-file-structure-hooks-section-structure-ecs-sample-function

import boto3
import os

client = boto3.client("codedeploy", region_name=os.environ.get("REGION"))


def handler(event, context):
  # Enter validation tests here

  client.put_lifecycle_event_hook_execution_status(
    deploymentId=event['DeploymentId'],
    lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
    status='Succeeded')  # status can be 'Succeeded' or 'Failed'
