use Mix.Config

config :kubot,
  slack_api_key: "${SLACK_API_KEY}",
  aws_bucket: "${AWS_BUCKET}",
  bot_name: "${BOT_NAME}",
  users: "${USERS}"

config :ex_aws,
  access_key_id: ["${AWS_ACCESS_KEY}", :instance_role],
  secret_access_key: ["${AWS_SECRET_KEY}", :instance_role]
