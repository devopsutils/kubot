use Mix.Config

config :kubot,
  slack_api_key: System.get_env("SLACK_API_KEY"),
  aws_bucket: System.get_env("AWS_BUCKET"),
  bot_name: System.get_env("BOT_NAME"),
  users: System.get_env("USERS")

config :ex_aws,
  access_key_id: [System.get_env("AWS_ACCESS_KEY"), :instance_role],
  secret_access_key: [System.get_env("AWS_SECRET_KEY"), :instance_role]
