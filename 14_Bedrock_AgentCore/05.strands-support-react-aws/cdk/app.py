#!/usr/bin/env python3
"""CDK app — staged classroom deploys: -c stage=1 .. -c stage=10"""

from __future__ import annotations

import os

import aws_cdk as cdk

from lauki_support_stack import LaukiSupportStack

app = cdk.App()

stage = int(app.node.try_get_context("stage") or os.environ.get("CDK_STAGE") or "10")
runtime_arn = (
    app.node.try_get_context("supportRuntimeArn")
    or os.environ.get("SUPPORT_RUNTIME_ARN")
    or ""
).strip()

if stage >= 10 and not runtime_arn:
    raise SystemExit(
        "Stage 10 needs the AgentCore Runtime ARN.\n"
        "  export SUPPORT_RUNTIME_ARN=arn:aws:bedrock-agentcore:...\n"
        "  npx cdk deploy -c stage=10 -c supportRuntimeArn=$SUPPORT_RUNTIME_ARN"
    )

env = cdk.Environment(
    account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
    region=os.environ.get("CDK_DEFAULT_REGION")
    or os.environ.get("AWS_REGION")
    or "us-east-1",
)

LaukiSupportStack(
    app,
    "LaukiSupportStack",
    stage=stage,
    support_runtime_arn=runtime_arn,
    env=env,
    description=f"Lauki Support classroom stack (stage {stage}/10)",
)

app.synth()
