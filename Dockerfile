ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG APPS_JSON_BASE64=W10=

FROM frappe/bench:latest AS builder

ARG FRAPPE_BRANCH
ARG FRAPPE_PATH
ARG APPS_JSON_BASE64

USER frappe

# Install frappe
RUN bench init \
  --frappe-branch=${FRAPPE_BRANCH} \
  --frappe-path=${FRAPPE_PATH} \
  --no-procfile \
  --no-backups \
  --skip-redis-config-generation \
  --verbose \
  /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Decode and install apps from apps.json
RUN if [ -n "${APPS_JSON_BASE64}" ] && [ "${APPS_JSON_BASE64}" != "W10=" ]; then \
  echo "${APPS_JSON_BASE64}" | base64 -d > /tmp/apps.json && \
  cat /tmp/apps.json && \
  for app in $(cat /tmp/apps.json | jq -r '.[] | @base64'); do \
    _jq() { echo ${app} | base64 -d | jq -r ${1}; }; \
    APP_URL=$(_jq '.url'); \
    APP_BRANCH=$(_jq '.branch // "version-15"'); \
    echo "Installing app from ${APP_URL} (branch: ${APP_BRANCH})"; \
    bench get-app --branch=${APP_BRANCH} ${APP_URL}; \
  done; \
fi

# Remove .git directories to reduce image size
RUN find apps -name ".git" -exec rm -rf {} + || true

FROM frappe/base:${FRAPPE_BRANCH}

USER frappe

# Copy bench from builder
COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Set up volumes and default command
VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/logs" \
]

CMD [ \
  "/home/frappe/frappe-bench/env/bin/gunicorn", \
  "--bind=0.0.0.0:8000", \
  "--threads=4", \
  "--workers=2", \
  "--worker-class=gthread", \
  "--worker-tmp-dir=/dev/shm", \
  "--timeout=120", \
  "--preload", \
  "frappe.app:application" \
]
