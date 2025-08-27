# FARMZ - Drupal FarmOS Project

A Drupal-based FarmOS project configured for deployment on Railway with PostgreSQL database.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Composer (PHP 8.4+)
- Git

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/modernflush-art/FARMZ.git
   cd FARMZ
   ```

2. **Install dependencies**
   ```bash
   composer install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Railway PostgreSQL DATABASE_URL
   ```

4. **Start local development server**
   ```bash
   docker-compose up -d
   ```

5. **Access the application**
   - Main application: http://localhost:8080
   - Alternative port: http://localhost:8081

### Railway Deployment

1. **Connect to Railway**
   - Create a new project in Railway
   - Connect your GitHub repository (FARMZ)
   - Choose deployment method: Dockerfile

2. **Configure environment variables**
   - `DATABASE_URL`: Your Railway PostgreSQL connection string
   - `DRUPAL_HASH_SALT`: Generate a random string for Drupal

3. **Deploy**
   - Railway will automatically build and deploy from the Dockerfile
   - Access your application via the Railway-provided URL

## 📁 Project Structure

```
FARMZ/
├── composer.json          # PHP dependencies (Drupal 11 + FarmOS 4.x)
├── composer.lock          # Locked dependency versions
├── Dockerfile             # Container configuration
├── docker-compose.yml     # Local development setup
├── .env.example           # Environment variables template
├── .gitignore            # Git ignore rules
└── farmOS/               # FarmOS modules (excluded from git)
```

## 🔧 Configuration

### Database
- **Local**: PostgreSQL via Railway proxy
- **Production**: Railway PostgreSQL service
- **Connection**: Uses `DATABASE_URL` environment variable

### Dependencies
- **Drupal Core**: 11.x
- **FarmOS**: 4.x-dev
- **PHP**: 8.4+

## 🛠 Development

### Adding new modules
```bash
composer require drupal/module_name
```

### Updating dependencies
```bash
composer update
git add composer.lock
git commit -m "chore: update dependencies"
```

### Database migrations
```bash
# Via Drush (if available)
drush updb
drush cr
```

## 🚀 Deployment

### Railway
1. Push changes to GitHub
2. Railway automatically deploys from main branch
3. Environment variables are managed in Railway dashboard

### Local testing
```bash
docker-compose up -d
docker-compose logs -f
```

## 📝 Notes

- The `farmOS/` directory is excluded from git (see .gitignore)
- Environment variables should never be committed to git
- Use Railway's environment variable management for production secrets

## 🔗 Links

- [FarmOS Documentation](https://farmos.org/)
- [Drupal Documentation](https://www.drupal.org/docs)
- [Railway Documentation](https://docs.railway.app/)