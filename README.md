# Home Lab Monitoring Stack Setup Instructions

## Prerequisites
- Ubuntu server with Docker and Docker Compose installed
- At least 4GB RAM and 20GB free disk space
- Network access to your Synology NAS

## Directory Structure Setup

Create the following directory structure:

```bash
mkdir -p homelab-monitoring/{prometheus,grafana/provisioning/{dashboards,datasources,notifiers},snmp-exporter,blackbox-exporter,ntopng,uptime-kuma/data,nginx-proxy-manager/{data,letsencrypt}}
cd homelab-monitoring
```

## Configuration Files

### 1. Prometheus Configuration (`prometheus/prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'snmp-synology'
    static_configs:
      - targets: ['YOUR_SYNOLOGY_IP']  # Replace with your Synology IP
    metrics_path: /snmp
    params:
      module: [synology]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: snmp-exporter:9116

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://prometheus:9090
        - http://grafana:3000
        - http://192.168.1.110:5000  # Replace with your Synology IP
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

### 2. SNMP Exporter Configuration (`snmp-exporter/snmp.yml`)

```yaml
synology:
  walk:
    - 1.3.6.1.2.1.1.3.0
    - 1.3.6.1.4.1.6574.1.5.1.0
    - 1.3.6.1.4.1.6574.1.5.2.0
    - 1.3.6.1.4.1.6574.2.1.1.5
    - 1.3.6.1.4.1.6574.2.1.1.6
  metrics:
    - name: synology_system_temp
      oid: 1.3.6.1.4.1.6574.1.2.0
      type: gauge
    - name: synology_power_status
      oid: 1.3.6.1.4.1.6574.1.3.0
      type: gauge
    - name: synology_disk_temp
      oid: 1.3.6.1.4.1.6574.2.1.1.6
      type: gauge
      indexes:
        - labelname: disk
          type: gauge
```

### 3. Blackbox Exporter Configuration (`blackbox-exporter/blackbox.yml`)

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
  tcp_connect:
    prober: tcp
    timeout: 5s
  ping:
    prober: icmp
    timeout: 5s
```

### 4. Grafana Datasource Configuration (`grafana/provisioning/datasources/datasource.yml`)

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

### 5. Ntopng Configuration (`ntopng/ntopng.conf`)

```
-i=eth0
-d=/var/lib/ntopng/ntopng.db
-w=3000
-P=/etc/ntopng/ntopng.pid
-u=ntopng
-g=ntopng
--disable-login
```

## Deployment Steps

1. **Create the directory structure and configuration files above**

2. **Update the configuration files with your specific details:**
   - Replace `YOUR_SYNOLOGY_IP` with your actual Synology NAS IP address
   - Update email settings in watchtower service if you want notifications

3. **Enable SNMP on your Synology NAS:**
   - Go to Control Panel > Terminal & SNMP
   - Enable SNMP service
   - Set community string to "public" (or customize in the config)

4. **Deploy the stack:**
   ```bash
   docker-compose up -d
   ```

5. **Verify all containers are running:**
   ```bash
   docker-compose ps
   ```

## Service Access URLs

Once deployed, you can access each service at:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| **Portainer** | http://your-server-ip:9000 | Create admin user on first visit |
| **Nginx Proxy Manager** | http://your-server-ip:81 | admin@example.com / changeme |
| **Prometheus** | http://your-server-ip:9090 | No authentication |
| **Grafana** | http://your-server-ip:3001 | admin / admin123 |
| **cAdvisor** | http://your-server-ip:8080 | No authentication |
| **Node Exporter** | http://your-server-ip:9100 | No authentication |
| **Uptime Kuma** | http://your-server-ip:3002 | Create admin user on first visit | Admin/Pow3rup?
| **Ntopng** | http://your-server-ip:3000 | No authentication |

## Post-Deployment Configuration

### Grafana Dashboard Setup

1. Login to Grafana (http://your-server-ip:3001)
2. Import popular dashboards:
   - Node Exporter Full: Dashboard ID `1860`
   - Docker Container & Host Metrics: Dashboard ID `179`
   - Synology NAS: Dashboard ID `14284`

### Uptime Kuma Setup

1. Access Uptime Kuma and create an admin account
2. Add monitors for your key services:
   - HTTP monitors for web services
   - TCP monitors for network services
   - Ping monitors for network connectivity

### Security Recommendations

1. **Change default passwords immediately**
2. **Use Nginx Proxy Manager to:**
   - Set up SSL certificates
   - Add authentication to exposed services
   - Configure reverse proxy rules

3. **Firewall rules:**
   ```bash
   # Allow only necessary ports
   sudo ufw allow 22    # SSH
   sudo ufw allow 80    # HTTP
   sudo ufw allow 443   # HTTPS
   sudo ufw allow 9000  # Portainer (consider restricting to local network)
   sudo ufw enable
   ```

## Maintenance

- **View logs:** `docker-compose logs -f [service_name]`
- **Update services:** `docker-compose pull && docker-compose up -d`
- **Backup volumes:** Regular backups of Docker volumes are recommended
- **Monitor disk usage:** The metrics data will grow over time

## Troubleshooting

- **Container won't start:** Check logs with `docker-compose logs [service_name]`
- **Can't access services:** Verify firewall rules and container status
- **SNMP not working:** Ensure SNMP is enabled on Synology and community string matches
- **Network monitoring issues:** Verify ntopng has proper network interface access

Your monitoring stack is now ready to provide comprehensive visibility into your home lab infrastructure!

