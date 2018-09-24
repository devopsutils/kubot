# Kubot

This is a simple elixir slack bot that works with AWS ECS. The purpose it to be able to control ECS from slack.

With this bot you can:

* Create a service
* Deploy a new revision (create a new task, update that service)
* Scale the Tasks
* Describe a service

## Installation

Fetch the dependencies: `mix deps.get && mix deps.compile`
Run the application `mix run --no-halt`
There are a couple environment variables you will need:

`MIX_ENV` - your env
`SLACK_API_KEY` - Slack API key
`BOT_NAME` - The name of your slack bot (used to verify message)
`AWS_BUCKET` - AWS Bucket that Service configurations are found
`AWS_ACCESS_KEY` - AWS Access Key to access the AWS bucket above
`AWS_SECRET_KEY` - AWS Secret Access Key to access the AWS bucket above
`TIMBER_LOGS_KEY` - Optional: [Timber.io](https://timber.io/) API key to aggregate logs
`USERS` - Optional: List of users that can use the slackbot. If not present anyone can use it.

## AWS Service Configuration

Your service configuration is what will tell the bot the information needed for each command. A good reference for all the options is from the [Ruby AWS SDK](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ECS/Client.html#update_service-instance_method). It is important to note the path this file needs to be within the AWS Bucket.

Bucket: "bucket.test"
App name: "AppTest"
environment: "test"

the full S3 path would be: `bucket.test/AppTest/test.json`

Example JSON File:
```
{
  "cpu": 128,
  "family": "test",
  "image": "000000000.dkr.ecr.us-east-1.amazonaws.com/test",
  "memory": 100,
  "name": "test",
  "portMappings": [
    {
      "hostPort": 4000,
      "containerPort": 4000,
      "protocol": "tcp"
    }
  ]
  "environmentVariables": [
    { "name": "ONE", "value": "ONE" }
    { "name": "TWO", "value": "TWO" }
  ],
  "cluster": "staging",
  "service": "test-staging",
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 0
  },
  desiredCount: 3
}
```
