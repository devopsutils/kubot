use Mix.Config

config :kubot,
  slack_api_key: "SLACK_API_KEY",
  aws_bucket: "test.kubot"

config :ex_aws,
  access_key_id: ["AWS_KEY", :instance_role],
  secret_access_key: ["AWS_SECRECT", :instance_role]
