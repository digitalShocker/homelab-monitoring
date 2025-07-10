#!/bin/bash
# Landing Page Setup Script

echo "Setting up Home Lab Landing Page..."

# Create landing page directory
mkdir -p landing-page

# Copy the HTML file (you'll need to save the HTML artifact as index.html)
echo "Please save the 'Home Lab Services Landing Page' HTML content as:"
echo "  landing-page/index.html"
echo ""

# Copy the nginx configuration (you'll need to save the nginx config artifact)
echo "Please save the 'Nginx Configuration for Landing Page' content as:"
echo "  landing-page/nginx.conf"
echo ""

# Get server IP for reference
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Your server IP is: $SERVER_IP"
echo ""

# Configure firewall for port 80
if command -v ufw &> /dev/null; then
    echo "Configuring firewall..."
    sudo ufw allow 80/tcp comment "Landing Page HTTP"
    echo "Port 80 opened for HTTP traffic"
else
    echo "UFW not found - ensure port 80 is open in your firewall"
fi

echo ""
echo "Setup steps:"
echo "1. Save the HTML and nginx config files in the landing-page/ directory"
echo "2. Add the landing-page service to your docker-compose.yml"
echo "3. Run: docker compose up -d landing-page"
echo "4. Access your landing page at: http://$SERVER_IP"
echo ""
echo "Directory structure should be:"
echo "homelab-monitoring/"
echo "├── docker-compose.yml"
echo "├── landing-page/"
echo "│   ├── index.html"
echo "│   └── nginx.conf"
echo "└── [other service directories...]"
echo ""

# Create a simple test to verify files are in place
cat > check_landing_setup.sh << 'EOF'
#!/bin/bash
echo "Checking landing page setup..."

if [ -f "landing-page/index.html" ]; then
    echo "✅ index.html found"
else
    echo "❌ index.html missing"
fi

if [ -f "landing-page/nginx.conf" ]; then
    echo "✅ nginx.conf found"
else
    echo "❌ nginx.conf missing"
fi

if grep -q "landing-page:" docker-compose.yml; then
    echo "✅ Landing page service found in docker-compose.yml"
else
    echo "❌ Landing page service not added to docker-compose.yml"
fi

echo ""
echo "Once all files are in place, run:"
echo "docker compose up -d landing-page"
EOF

chmod +x check_landing_setup.sh

echo "Created check_landing_setup.sh - run this to verify your setup"
echo ""
echo "Landing page will be available at:"
echo "  http://$SERVER_IP (main dashboard)"
echo "  http://$SERVER_IP/grafana (direct to Grafana)"
echo "  http://$SERVER_IP/prometheus (direct to Prometheus)"
echo "  http://$SERVER_IP/jellyfin (direct to Jellyfin)"
echo "  etc..."