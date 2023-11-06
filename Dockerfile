FROM codilitydeploy/ruby2.4.0

# Receiving environment variable
ARG rails_env=production
ARG timezone="UTC"
ARG aws_access_key_id=""
ARG aws_secret_access_key=""
ARG aws_region=""
ARG cloudfront_url=""
ARG s3_bucket_name=""
ARG shared_config_path="/application/config"
ARG map_api_key=""
ARG airbrake_project_id=""
ARG airbrake_project_key=""
ARG default_from_email=""
ARG elasticsearch_url=""
ARG timeout_seconds=""
ARG onfleet_api_key=""
ARG oauth_client_id=""
ARG oauth_client_secret=""
ARG stripe_publishable_key=""
ARG stripe_secret_key=""
ARG zendesk_url="https://chowmill.zendesk.com/api/v2"
ARG zendesk_username=""
ARG zendesk_api_token=""
ARG redis_port=""
ARG redis_host=""
ARG redis_server=""
ARG INSTALL=app

ENV RAILS_ENV=${rails_env}
ENV TIMEZONE=${timezone}
ENV AWS_ACCESS_KEY_ID=${aws_access_key_id}
ENV AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
ENV AWS_REGION=${aws_region}
ENV CLOUDFRONT_URL=${cloudfront_url}
ENV S3_BUCKET_NAME=${s3_bucket_name}
ENV SHARED_CONFIG_PATH=${shared_config_path}
ENV MAP_API_KEY=${map_api_key}
ENV AIRBRAKE_PROJECT_ID=${airbrake_project_id}
ENV AIRBRAKE_PROJECT_KEY=${airbrake_project_key}
ENV DEFAULT_FROM_EMAIL=${default_from_email}
ENV ELASTICSEARCH_URL=${elasticsearch_url}
ENV TIMEOUT_SECONDS=${timeout_seconds}
ENV ONFLEET_API_KEY=${onfleet_api_key}
ENV OAUTH_CLIENT_ID=${oauth_client_id}
ENV OAUTH_CLIENT_SECRET=${oauth_client_secret}
ENV STRIPE_PUBLISHABLE_KEY=${stripe_publishable_key}
ENV STRIPE_SECRET_KEY=${stripe_secret_key}
ENV ZENDESK_URL=${zendesk_url}
ENV ZENDESK_USERNAME=${zendesk_username}
ENV ZENDESK_API_TOKEN=${zendesk_api_token}
ENV REDIS_PORT=${redis_port}
ENV REDIS_HOST=${redis_host}
ENV REDIS_SERVER=${redis_server}


# Change to the application's directory
WORKDIR /application

# RUN curl https://deb.nodesource.com/setup_12.x | bash
# RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
# RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# RUN apt-get update && apt-get install -y nodejs yarn


#RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
#RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
#RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
#   && apt-get update -qq && apt-get install -y build-essential && apt install -y nodejs

# Copy Gemfile to application directory
COPY Gemfile* ./

# Fixing executable files permissions
#RUN chmod -R +x /application/bin/

# Install gems for production
RUN bundle install

# Copy application code
COPY . .

#RUN mkdir shared
RUN mkdir /application/shared
RUN chmod -R 0777 /application/shared/

RUN mkdir /application/log
RUN touch /application/log/sidekiq.log
RUN mkdir -pv /application/tmp/pids/
RUN touch /application/tmp/pids/sidekiq-0.pid

RUN mkdir /application/public/ordersummary
RUN mkdir /application/public/download_pdfs
RUN mkdir /application/public/labels_csvs
RUN mkdir /application/public/fax_summary

RUN chmod +x /application/bin/rails
RUN chmod +x /application/bin/rake

# RUN mv develop.env .env
# RUN if [ "$INSTALL" = "app" ]; then rails assets:precompile; fi
# RUN rails assets:precompile

RUN if [ "$RAILS_ENV" != "local" ]; then rails assets:precompile; fi


# RUN if [ "$INSTALL" = "cron" ]; then apt install -y wkhtmltopdf; fi

EXPOSE 3000

# Start the application server
ENTRYPOINT ["/bin/bash","/application/bin/docker-entrypoint.sh"]