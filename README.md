# 🎵 XSigned Backend

A comprehensive Flask-based backend for managing music marketing campaigns, designed for deployment on Raspberry Pi with Cloudflare Tunnel for secure, reliable access.

## 🌟 Features

- **User Management** - Create and manage user accounts with email validation
- **Campaign Management** - Create, update, and track marketing campaigns
- **Task Management** - Organize campaign tasks with status tracking
- **PostgreSQL Database** - Robust data storage with SQLAlchemy ORM
- **RESTful API** - Clean, documented API endpoints
- **Cloudflare Tunnel** - Secure access without port forwarding
- **Docker Containerization** - Easy deployment and scaling
- **Production Ready** - Health checks, logging, monitoring, and backups

## 🚀 Quick Start

### Prerequisites

- Raspberry Pi 4/5 with Ubuntu/Raspberry Pi OS
- Docker and Docker Compose
- Cloudflare account with domain
- SSH access to your Pi

### 1. Clone and Setup

```bash
git clone https://github.com/your-username/xsigned-backend.git
cd xsigned-backend
./run.sh env-setup  # Creates .env from template
```

### 2. Configure Environment

Edit `.env` file with your values:

```bash
# Required configuration
DB_PASSWORD=your_secure_password
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token
FLASK_SECRET_KEY=your_secret_key
DOMAIN=xsigned.ai
```

### 3. Deploy

```bash
./run.sh validate  # Check configuration
./run.sh deploy    # Full deployment to Pi
```

### 4. Verify

```bash
./run.sh status    # Check system health
./run.sh test      # Test API endpoints
```

## 🏗️ Architecture

```
Internet → Cloudflare → Tunnel → Nginx → Backend/Frontend
                                    ↓
                               PostgreSQL
```

### Services

- **Backend**: Flask API (Python 3.11)
- **Frontend**: React application
- **Database**: PostgreSQL 15
- **Proxy**: Nginx with rate limiting
- **Tunnel**: Cloudflare Tunnel for secure access

## 📖 API Documentation

### Endpoints

#### Users

- `GET /api/users` - List all users
- `POST /api/users` - Create new user
- `GET /api/users/{id}` - Get specific user
- `GET /api/users/{id}/campaigns` - Get user's campaigns

#### Campaigns

- `GET /api/campaigns` - List all campaigns
- `POST /api/campaigns` - Create new campaign
- `GET /api/campaigns/{id}` - Get specific campaign
- `PUT /api/campaigns/{id}` - Update campaign
- `DELETE /api/campaigns/{id}` - Delete campaign

#### Health

- `GET /health` - Application health check
- `GET /api/health` - API health check

### Example Requests

#### Create User

```bash
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "username": "musician1"}'
```

#### Create Campaign

```bash
curl -X POST http://localhost/api/campaigns \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "name": "Album Launch",
    "description": "Marketing campaign for new album",
    "target_audience": "Young adults 18-35"
  }'
```

## 🛠️ Development

### Local Development

```bash
./run.sh dev        # Start development environment
./run.sh dev-logs   # View development logs
```

### Testing

```bash
./run.sh test       # Run API integration tests
./run.sh health     # Quick health check
```

### Database Operations

```bash
./run.sh db-shell   # Connect to database
./run.sh backup     # Create backup
./run.sh db-reset   # Reset database (⚠️ destructive)
```

## 🔧 Task Runner Commands

The `./run.sh` script provides convenient access to all operations:

### Deployment

- `./run.sh validate` - Validate configuration
- `./run.sh deploy` - Full deployment
- `./run.sh setup-tunnel` - Configure Cloudflare Tunnel

### Monitoring

- `./run.sh status` - System status overview
- `./run.sh logs` - View recent logs
- `./run.sh test` - API integration tests
- `./run.sh health` - Quick health check

### Service Management

- `./run.sh start` - Start services
- `./run.sh stop` - Stop services
- `./run.sh restart` - Restart services
- `./run.sh rebuild` - Rebuild and restart

### Maintenance

- `./run.sh backup` - Database backup
- `./run.sh clean` - Clean Docker resources
- `./run.sh update` - Update and restart

## 📊 Monitoring & Maintenance

### Automated Features

- **Health Checks** - Built-in health monitoring for all services
- **Automatic Backups** - Daily database backups at 2 AM
- **Log Rotation** - Automatic log management
- **Service Recovery** - Automatic restart on failures
- **Resource Monitoring** - System resource tracking

### Manual Monitoring

```bash
./run.sh status     # Comprehensive system status
./run.sh logs       # Recent logs from all services
docker stats        # Real-time resource usage
```

## 🔒 Security Features

- **Cloudflare Tunnel** - No open ports, secure connection
- **CORS Configuration** - Proper cross-origin request handling
- **Rate Limiting** - API rate limiting to prevent abuse
- **Security Headers** - Standard security headers configured
- **Environment Isolation** - Secure environment variable handling
- **Database Security** - Encrypted connections and access controls

## 📁 Project Structure

```
xsigned-backend/
├── src/                    # Application source code
│   ├── app.py             # Main Flask application
│   ├── models/            # Database models
│   ├── routes/            # API route handlers
│   ├── services/          # Business logic
│   └── database/          # Database configuration
├── docker-compose.*.yml   # Docker configurations
├── nginx-*.conf          # Nginx configurations
├── *.sh                  # Deployment and utility scripts
├── DEPLOYMENT.md         # Detailed deployment guide
├── DEPLOYMENT_CHECKLIST.md # Step-by-step checklist
└── requirements.txt      # Python dependencies
```

## 🔄 CI/CD and Updates

### Update Deployment

```bash
git pull origin main
./run.sh update
```

### Rollback

```bash
git checkout previous-commit
./run.sh rebuild
```

## 🐛 Troubleshooting

### Common Issues

#### Services Won't Start

```bash
./run.sh status        # Check service status
docker-compose logs    # View error logs
./run.sh restart      # Restart services
```

#### Database Connection Issues

```bash
./run.sh db-shell     # Test database connection
./run.sh db-reset     # Reset database if needed
```

#### Tunnel Not Working

```bash
sudo systemctl status cloudflared  # Check tunnel service
sudo journalctl -u cloudflared -f  # View tunnel logs
```

### Performance Issues

```bash
docker stats          # Check resource usage
./run.sh clean        # Clean up Docker resources
free -h && df -h      # Check system resources
```

## 🔮 Future Enhancements

### Planned Features

- [ ] OAuth2 authentication (Google, Spotify, Apple)
- [ ] Social media integrations (Instagram, TikTok, Twitter)
- [ ] Analytics dashboard
- [ ] Email campaign management
- [ ] File upload for media assets
- [ ] Advanced campaign analytics
- [ ] User role management
- [ ] API rate limiting tiers
- [ ] Webhook notifications

### Technical Improvements

- [ ] Redis caching layer
- [ ] Elasticsearch for search
- [ ] Message queue (Celery)
- [ ] API versioning
- [ ] GraphQL endpoint
- [ ] Mobile app API
- [ ] Real-time notifications

## 📞 Support

### Documentation

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Comprehensive deployment guide
- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - Step-by-step checklist

### Quick Help

```bash
./run.sh help         # Available commands
./run.sh status       # System health check
./run.sh test         # API functionality test
```

### Community

- GitHub Issues: Report bugs and request features
- Discussions: Share ideas and get help

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flask and SQLAlchemy teams for excellent frameworks
- Cloudflare for secure tunnel technology
- Docker for containerization
- PostgreSQL for robust database capabilities
- The open-source community for inspiration and tools

---

## 🎉 Ready to Launch!

Your music marketing campaign backend is ready for production at **https://xsigned.ai**

**Next Steps:**

1. Deploy your React frontend
2. Connect to social media APIs
3. Implement OAuth authentication
4. Start managing your music campaigns!

For detailed deployment instructions, see [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
