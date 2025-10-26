import Config

config :zodish,
  #   defines the expected behavior when trying to coerce a type that
  # ↓ doesn't support coercion, options are :raise, :warn or :ignore
  on_unsupported_coercion: :warn
