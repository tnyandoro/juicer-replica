# Dockerfile
# Ruby Commercial Citrus Juicer Simulator

FROM ruby:3.2.2-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5

# Copy application code
COPY . .

# Expose API port
EXPOSE 4567

# Default command: run tests
CMD ["bundle", "exec", "rspec"]