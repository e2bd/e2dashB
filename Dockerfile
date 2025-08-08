FROM python:3.11-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DISPLAY=:99 \
    PATH="/usr/local/bin:${PATH}" \
    CHROME_BIN="/usr/bin/google-chrome-stable" \
    CHROMEDRIVER_PATH="/usr/local/bin/chromedriver" \
    WDM_LOCAL="1" \
    WDM_LOG_LEVEL="0"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget gnupg ca-certificates xvfb unzip xauth \
        libasound2 libatk1.0-0 libc6 libcairo2 libcups2 \
        libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 \
        libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
        libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
        libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
        libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 \
        libxtst6 libnss3 fonts-liberation libappindicator3-1 \
        libdrm2 libxkbcommon0 libxshmfence1 && \
    rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -yf && \
    rm google-chrome-stable_current_amd64.deb

# Install ChromeDriver
RUN CHROME_MAJOR_VERSION=$(google-chrome-stable --version | sed -E 's/.* ([0-9]+)\..*/\1/') && \
    CHROME_FULL_VERSION=$(google-chrome-stable --version | awk '{print $3}') && \
    echo "Chrome version: $CHROME_FULL_VERSION" && \
    wget -qO /tmp/chromedriver.zip \
      "https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$CHROME_FULL_VERSION/linux64/chromedriver-linux64.zip" && \
    unzip -j /tmp/chromedriver.zip "chromedriver-linux64/chromedriver" -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip && \
    ln -s /usr/local/bin/chromedriver /usr/bin/chromedriver

# Verify installations
RUN google-chrome-stable --version && \
    chromedriver --version && \
    ldd /usr/bin/google-chrome-stable && \
    ldd /usr/local/bin/chromedriver

# Create app user
RUN groupadd -r appuser && \
    useradd -r -g appuser -m -d /home/appuser appuser && \
    chown -R appuser:appuser /home/appuser && \
    chmod 755 /usr/local/bin/chromedriver

# Allow non-root Chrome
RUN echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/userns.conf

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

USER appuser

CMD ["sh", "-c", "xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' python bot.py"]
