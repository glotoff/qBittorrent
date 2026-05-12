# Docker Setup Guide for qBittorrent

This guide will help you build and run qBittorrent in a Docker container with the download content feature you just implemented.

**Base Image:** Ubuntu 26.04

## Prerequisites

- Docker installed on your system
- Docker Compose (optional, for easier management)

## Quick Start with Docker Compose (Recommended)

### 1. Create necessary directories

```bash
mkdir -p config downloads
```

### 2. Build and run the container

```bash
docker-compose up -d --build
```

### 3. Access the WebUI

Open your browser and navigate to: `http://localhost:8080`

**Default credentials:**
- Username: `admin`
- Password: `adminadmin` (you'll be prompted to change it on first login)

## Manual Docker Build

### Build the image

```bash
docker build -t qbittorrent:latest .
```

### Run the container

```bash
docker run -d \
  --name qbittorrent \
  -p 8080:8080 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -v $(pwd)/config:/home/qbittorrent/.local/share/qBittorrent \
  -v $(pwd)/downloads:/home/qbittorrent/downloads \
  -e QBT_WEBUI_PORT=8080 \
  qbittorrent:latest
```

## Configuration

### Environment Variables

- `QBT_WEBUI_PORT`: WebUI port (default: 8080)
- `QBT_DOWNLOADS_PATH`: Downloads directory (default: /home/qbittorrent/downloads)

### Volumes

- `/home/qbittorrent/.local/share/qBittorrent`: Configuration files
- `/home/qbittorrent/downloads`: Downloaded files

### Ports

- `8080`: WebUI interface
- `6881`: BitTorrent TCP port
- `6881/udp`: BitTorrent UDP port

## Using the Download Content Feature

Once the container is running and you've accessed the WebUI:

1. Right-click on any torrent in the transfer list
2. Select "Download content" from the context menu
3. The torrent's content will be downloaded as:
   - Single file: The file itself
   - Directory: A ZIP archive containing all files

## Management Commands

### View logs

```bash
docker-compose logs -f qbittorrent
```

### Stop the container

```bash
docker-compose down
```

### Restart the container

```bash
docker-compose restart
```

### Update the image

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Access container shell (for debugging)

```bash
docker exec -it qbittorrent bash
```

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker-compose logs qbittorrent
```

### Can't access WebUI

1. Verify the container is running: `docker ps`
2. Check if port 8080 is available: `netstat -tulpn | grep 8080`
3. Check firewall settings

### Permission issues with downloads

The container runs as a non-root user (UID 1000). Ensure your local directories have proper permissions:
```bash
sudo chown -R 1000:1000 config downloads
```

## Building for Different Architectures

To build for ARM (e.g., Raspberry Pi):

```bash
docker buildx build --platform linux/arm64 -t qbittorrent:latest .
```

## Security Considerations

1. Change the default WebUI password immediately after first login
2. Consider using a reverse proxy (nginx/traefik) with SSL for production use
3. Don't expose the BitTorrent ports publicly unless necessary
4. Use a VPN if you want to hide your IP address

## Performance Tips

1. Use a dedicated volume for downloads (not a bind mount) for better performance
2. Increase memory limits if downloading large torrents
3. Use SSD storage for better I/O performance

## Uninstall

To remove everything:

```bash
docker-compose down -v
docker rmi qbittorrent:latest
rm -rf config downloads
```
