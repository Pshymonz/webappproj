FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Base packages
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    wget \
    git \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Download GitHub Clone.
RUN git clone --branch main --depth 1 https://github.com/Pshymonz/webappproj.git  

# ----------------------------
# Ansible
# ----------------------------
RUN apt-get update && apt-get install -y ansible && rm -rf /var/lib/apt/lists/*

# ----------------------------
# kubectl
# ----------------------------
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
    | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
    > /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && apt-get install -y kubectl && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------
# Terraform
# ----------------------------
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------
# Jenkins
# ----------------------------
RUN curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
    | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
    https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list && \
    apt-get update && apt-get install -y jenkins && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------
# Prometheus
# ----------------------------
RUN useradd --no-create-home --shell /bin/false prometheus && \
    mkdir /etc/prometheus /var/lib/prometheus && \
    cd /tmp && \
    wget https://github.com/prometheus/prometheus/releases/download/v3.8.1/prometheus-3.8.1.linux-arm64.tar.gz && \
    tar xvf prometheus-3.8.1.linux-arm64.tar.gz && \
    PROM_DIR=$(find . -maxdepth 1 -type d -name "prometheus-*") && \
    cp $PROM_DIR/prometheus /usr/local/bin/ && \
    cp $PROM_DIR/promtool /usr/local/bin/ && \
    rm -rf /tmp/prometheus*

# ----------------------------
# Prometheus config
# ----------------------------
RUN cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

# ----------------------------
# Supervisor config
# ----------------------------
RUN mkdir -p /etc/supervisor/conf.d

RUN cat <<EOF > /etc/supervisor/conf.d/jenkins.conf
[program:jenkins]
command=/usr/bin/java -jar /usr/share/java/jenkins.war
user=jenkins
autostart=true
autorestart=true
stdout_logfile=/var/log/jenkins.log
stderr_logfile=/var/log/jenkins.err
EOF

RUN cat <<EOF > /etc/supervisor/conf.d/prometheus.conf
[program:prometheus]
command=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
autostart=true
autorestart=true
stdout_logfile=/var/log/prometheus.log
stderr_logfile=/var/log/prometheus.err
EOF

# ----------------------------
# Ports
# ----------------------------
EXPOSE 8080 9090

# ----------------------------
# Start Supervisor
# ----------------------------
CMD ["/usr/bin/supervisord", "-n"]


