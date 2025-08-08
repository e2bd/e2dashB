# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ┃ Dockerfile for E2 Dashboard Bot (Koyeb / Container)
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FROM python:3.11-slim-bullseye

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DISPLAY=:99 \
    PATH="/usr/local/bin:${PATH}" \
    HOME=/home/appuser \
    WDM_CACHE_PATH="" \
    CHROMEDRIVER_PATH="/usr/local/bin/chromedriver" \
    CHROME_BIN="/usr/bin/google-chrome-stable"

# 1) Install system dependencies
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

# 2) Install Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -yf && \
    rm google-chrome-stable_current_amd64.deb && \
    google-chrome-stable --version

# 3) Install matching ChromeDriver
RUN CHROME_VER=$(google-chrome-stable --version | awk '{print $3}') && \
    echo "→ Chrome version: $CHROME_VER" && \
    wget -qO /tmp/chromedriver.zip \
      "https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VER/linux64/chromedriver-linux64.zip" && \
    unzip -j /tmp/chromedriver.zip "chromedriver-linux64/chromedriver" -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip && \
    chromedriver --version

# 4) Verify Chrome and ChromeDriver
RUN ldd /usr/bin/google-chrome-stable && \
    ldd /usr/local/bin/chromedriver && \
    google-chrome-stable --version && \
    chromedriver --version

# 5) Create non-root user with proper permissions
RUN groupadd -r appuser && \
    useradd -r -g appuser -m -d /home/appuser appuser && \
    chown -R appuser:appuser /home/appuser && \
    chmod 755 /home/appuser && \
    chmod 755 /usr/local/bin/chromedriver

# 6) Allow non-root user to run Chrome (Koyeb-specific)
RUN echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/userns.conf

# 7) Set up application directory
WORKDIR /app
COPY requirements.txt ./

# 8) Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 9) Copy application files
COPY . .

# 10) Set user and permissions
USER appuser

# 11) Launch command with Xvfb
CMD ["sh", "-c", "xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' python bot.py"]
