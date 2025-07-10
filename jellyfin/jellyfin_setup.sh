#!/bin/bash
# Jellyfin Setup Script for Home Lab

echo "Setting up Jellyfin media server..."

# Get user ID and group ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "User ID: $USER_ID"
echo "Group ID: $GROUP_ID" 
echo "Server IP: $SERVER_IP"

# Create Jellyfin directories
echo "Creating Jellyfin directories..."
mkdir -p jellyfin/{config,cache}

# Set proper permissions
sudo chown -R $USER_ID:$GROUP_ID jellyfin/
chmod -R 755 jellyfin/

echo ""
echo "IMPORTANT: You need to update the docker-compose.yml file with your media paths!"
echo ""
echo "Current examples in docker-compose.yml:"
echo "  - /path/to/your/movies:/media/movies:ro"
echo "  - /path/to/your/tv-shows:/media/tv:ro"
echo "  - /path/to/your/music:/media/music:ro"
echo "  - /path/to/your/photos:/media/photos:ro"
echo ""
echo "Common media storage locations to check:"

# Check common media locations
echo "Checking for common media directories..."

# Check current user's directories
if [ -d "$HOME/Videos" ]; then
    echo "  Found: $HOME/Videos"
fi

if [ -d "$HOME/Movies" ]; then
    echo "  Found: $HOME/Movies"
fi

if [ -d "$HOME/Music" ]; then
    echo "  Found: $HOME/Music"
fi

if [ -d "$HOME/Pictures" ]; then
    echo "  Found: $HOME/Pictures"
fi

# Check for external drives
echo ""
echo "Mounted drives that might contain media:"
df -h | grep -E '/media|/mnt|/home' | grep -v tmpfs

echo ""
echo "Network shares (if any):"
mount | grep -E 'cifs|nfs'

echo ""
echo "Example docker-compose.yml volume mappings for common setups:"
echo ""
echo "# If your media is in your home directory:"
echo "  - $HOME/Videos/Movies:/media/movies:ro"
echo "  - $HOME/Videos/TV-Shows:/media/tv:ro"
echo "  - $HOME/Music:/media/music:ro"
echo "  - $HOME/Pictures:/media/photos:ro"
echo ""
echo "# If your media is on an external drive (e.g., /media/username/MyDrive):"
echo "  - /media/$USER/MyDrive/Movies:/media/movies:ro"
echo "  - /media/$USER/MyDrive/TV:/media/tv:ro"
echo ""
echo "# If your media is on a NAS or network share:"
echo "  - /mnt/nas/movies:/media/movies:ro"
echo "  - /mnt/nas/tv:/media/tv:ro"

# Check if we're on a system with hardware acceleration possibilities
echo ""
echo "Hardware acceleration check:"

# Check for Intel graphics
if [ -d "/dev/dri" ]; then
    echo "  Intel/AMD graphics found - hardware acceleration available"
    echo "  Uncomment the Intel hardware acceleration section in docker-compose.yml"
    ls -la /dev/dri/
fi

# Check for NVIDIA
if command -v nvidia-smi &> /dev/null; then
    echo "  NVIDIA GPU found - hardware acceleration available"
    echo "  Uncomment the NVIDIA hardware acceleration section in docker-compose.yml"
    nvidia-smi --query-gpu=name --format=csv,noheader
fi

echo ""
echo "Firewall configuration:"
echo "Opening ports for Jellyfin..."

# Configure firewall
if command -v ufw &> /dev/null; then
    sudo ufw allow 8096/tcp comment "Jellyfin HTTP"
    sudo ufw allow 8920/tcp comment "Jellyfin HTTPS"
    sudo ufw allow 7359/udp comment "Jellyfin Discovery"
    sudo ufw allow 1900/udp comment "Jellyfin DLNA"
    echo "  Firewall rules added for Jellyfin"
else
    echo "  UFW not found - manually configure firewall if needed"
fi

echo ""
echo "Setup complete! Next steps:"
echo ""
echo "1. Edit docker-compose.yml and update these settings:"
echo "   - Replace '/path/to/your/...' with actual media directory paths"
echo "   - Update 'your-server-ip' with: $SERVER_IP"
echo "   - Update PUID to: $USER_ID"
echo "   - Update PGID to: $GROUP_ID"
echo ""
echo "2. Start Jellyfin:"
echo "   docker compose up -d jellyfin"
echo ""
echo "3. Access Jellyfin web interface:"
echo "   http://$SERVER_IP:8096"
echo ""
echo "4. Complete the initial setup wizard"
echo ""
echo "5. For Samsung TV, install 'Jellyfin for Samsung TV' from the Samsung App Store"
echo "   or use the built-in web browser to access the web interface"
echo ""
echo "6. Check monitoring in Prometheus:"
echo "   http://$SERVER_IP:9090/targets (look for jellyfin targets)"
