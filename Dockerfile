# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ┃ Dockerfile for E2 Dashboard Bot (Koyeb / Container)
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FROM python:3.11-slim-bullseye

# Prevent prompts and make Python output immediately
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DISPLAY=:99 \
    PATH="/usr/local/bin:${PATH}"

# 1) Install Chrome deps + Xvfb + unzip etc.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget gnupg ca-certificates xvfb unzip xauth \
      libasound2 libatk1.0-0 libcairo2 libcups2 libdbus-1-3 \
      libexpat1 libfontconfig1 libgbm1 libgcc1 libgdk-pixbuf2.0-0 \
      libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 \
      libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 \
      libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
      libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
      libnss3 && \
    rm -rf /var/lib/apt/lists/*

# 2) Download & install Google Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    dpkg -i google-chrome-stable_current_amd64.deb && \
    apt-get update && apt-get install -yf && \
    rm google-chrome-stable_current_amd64.deb

# 3) Fetch matching ChromeDriver from Chrome for Testing
RUN CHROME_VER=$(google-chrome-stable --version | awk '{print $3}') && \
    echo "→ Chrome version: $CHROME_VER" && \
    wget -qO /tmp/chromedriver.zip \
      "https://storage.googleapis.com/chrome-for-testing/$CHROME_VER/linux64/chromedriver-linux64.zip" && \
    unzip -j /tmp/chromedriver.zip chromedriver-linux64/chromedriver -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/chromedriver && \
    rm /tmp/chromedriver.zip

# 4) Sanity-check that chromedriver is in place
RUN ls -l /usr/local/bin/chromedriver && \
    file    /usr/local/bin/chromedriver && \
    which   chromedriver

# 5) Create a non-root user for security
RUN groupadd -r appuser && \
    useradd -r -g appuser -m -d /home/appuser appuser

# 6) Switch to app dir & user, install Python deps
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# 7) Copy your bot code into the image
COPY . .

USER appuser

# 8) Launch under Xvfb so Chrome can run headlessly
CMD ["sh", "-c", "xvfb-run --auto-servernum --server-args='-screen 0 1920x1080x24' python bot.py"]
