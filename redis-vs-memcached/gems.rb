source "https://rubygems.org"

gem "sus"
gem "sus-fixtures-benchmark"
gem "sus-fixtures-async"

gem "logger"
gem "redis"

# gem "dalli"
# gem "dalli", git: "https://github.com/shopify/dalli", branch: "main"
gem "dalli", git: "https://github.com/shopify/dalli", branch: "nickamorim/sock-sync"

gem "async-redis"
