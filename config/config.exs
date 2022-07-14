# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :riax, RiaxWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: RiaxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Riax.PubSub,
  live_view: [signing_salt: "ZtPdO1j7"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :riax, Riax.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :sasl,
  errlog_type: :error
config :riax, RiaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Aq2IH+MBzO3h1LgvK3EQn2Dmi2Cj2N55++zmEFahcmLJARgior2VAzzyFD7tHQS9",
  render_errors: [view: RiaxWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RiaxWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "d0pWDhfsxTFfXBvWMjK14lAKelVTQKGS"] #new

config :riak_core,
  schema_dirs: ['priv']
