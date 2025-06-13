# 🔐 Enable SSH on Raspberry Pi

## Method 1: Physical Access (Monitor + Keyboard)

### Via Terminal

```bash
# Enable SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Check if it's running
sudo systemctl status ssh
```

### Via raspi-config (Raspberry Pi OS)

```bash
sudo raspi-config
# Navigate to: 3 Interface Options → P2 SSH → Yes → Finish
```

## Method 2: SD Card Access (No Physical Access)

If you can remove the SD card and access it on another computer:

1. **Insert SD card into your computer**
2. **Navigate to the boot partition** (usually shows as "bootfs" or "boot")
3. **Create an empty file named `ssh`** (no extension):

   ```bash
   # On macOS/Linux
   touch /Volumes/bootfs/ssh

   # On Windows
   # Create empty file named "ssh" in the boot drive
   ```

4. **Safely eject and reinsert SD card into Pi**
5. **Boot the Pi** - SSH will be enabled automatically

## Method 3: Enable WiFi + SSH via SD Card

If you need both WiFi and SSH, create these files on the boot partition:

### Create `ssh` file (empty)

```bash
touch /Volumes/bootfs/ssh
```

### Create `wpa_supplicant.conf` file

```bash
cat > /Volumes/bootfs/wpa_supplicant.conf << 'EOF'
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="YOUR_WIFI_NAME"
    psk="YOUR_WIFI_PASSWORD"
}
EOF
```

## Verify SSH is Working

After enabling SSH, test the connection:

```bash
# Find your Pi's IP address
nmap -sn 192.168.1.0/24  # Adjust network range as needed

# Or check your router's admin page for connected devices

# Test SSH connection
ssh colin@192.168.86.70  # Use your Pi's actual IP
```

## Set Up SSH Keys (Recommended)

Once SSH is working, set up key-based authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy key to Pi
ssh-copy-id colin@192.168.86.70

# Test passwordless login
ssh colin@192.168.86.70
```

## Troubleshooting

### SSH Still Not Working?

1. **Check if SSH is running on Pi:**

   ```bash
   sudo systemctl status ssh
   sudo netstat -tlnp | grep :22
   ```

2. **Check firewall (if enabled):**

   ```bash
   sudo ufw status
   sudo ufw allow ssh
   ```

3. **Check SSH config:**

   ```bash
   sudo nano /etc/ssh/sshd_config
   # Ensure: PermitRootLogin no (or yes for root)
   # Ensure: PasswordAuthentication yes (initially)
   sudo systemctl restart ssh
   ```

4. **Network connectivity:**
   ```bash
   ping 192.168.86.70  # Test basic connectivity
   telnet 192.168.86.70 22  # Test SSH port
   ```

## After SSH is Working

Once SSH is enabled, you can use our deployment script:

```bash
./run.sh deploy-dev
```

This will automatically sync files and set up the development environment on your Pi!
