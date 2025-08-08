FROM python:3.11-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DISPLAY=:99 \
    HOME=/home/appuser

# Install dependencies including xauth and unzip
# Replace your existing Chrome install section with:
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxss1 libgbm-dev fonts-liberation libappindicator3-1 \
    && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Sanity check
# Add after chromedriver installation
RUN google-chrome-stable --version && \
    /usr/local/bin/chromedriver --version && \
    ldd /usr/local/bin/chromedriver

# Download matching ChromeDriver
RUN FULL=$(google-chrome-stable --version \
      | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') && \
    echo "Downloading matching CfT ChromeDriver $FULL…" && \
    wget -qO /tmp/chromedriver.zip \
      "https://storage.googleapis.com/chrome-for-testing-public/$FULL/linux64/chromedriver-linux64.zip" && \
    unzip -j /tmp/chromedriver.zip "chromedriver-linux64/chromedriver" -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip

# Environment variable for WebDriver Manager
ENV WDM_CACHE_PATH=""

# Create non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser -m -d /home/appuser appuser

# After creating appuser
RUN chown -R appuser:appuser /home/appuser && \
    chmod 755 /home/appuser && \
    chmod 755 /usr/local/bin/chromedriver

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt
COPY . .

USER appuser

CMD ["sh", "-c", "xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' python bot.py"]
