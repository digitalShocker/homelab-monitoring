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
