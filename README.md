# SonarQube Server with Docker

This repository contains Docker configuration for running SonarQube with PostgreSQL for continuous code quality inspection.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (version 19.03.0+)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 1.27.0+)
- At least 4GB of RAM allocated to Docker
- Recommended: 2 CPUs or more

## System Requirements

SonarQube requires specific system configurations to run properly:

### For Windows

1. Increase virtual memory (pagefile) to at least 4GB
2. Set the following system environment variable:
   - `SONARQUBE_JAVAOPTS=-Xmx2G -Xms1G`

### For Linux

1. Set the following kernel parameters:
   ```bash
   sysctl -w vm.max_map_count=262144
   sysctl -w fs.file-max=65536
   ```
2. Set the following user limits:
   ```bash
   ulimit -n 65536
   ulimit -u 4096
   ```

## Setup and Installation

1. Clone this repository or copy the `docker-compose.yml` file to your desired location

2. Start SonarQube and PostgreSQL:
   ```bash
   docker-compose up -d
   ```

3. Access SonarQube at: http://localhost:9000

4. Log in with default credentials:
   - Username: `admin`
   - Password: `admin`
   - You'll be prompted to change the password on first login

## Configuration

### Environment Variables

The following environment variables can be modified in the `docker-compose.yml` file:

#### SonarQube
- `SONAR_JDBC_URL`: JDBC URL for connecting to PostgreSQL
- `SONAR_JDBC_USERNAME`: Database username
- `SONAR_JDBC_PASSWORD`: Database password

#### PostgreSQL
- `POSTGRES_USER`: Database username
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name

### Persistent Data

The following Docker volumes are created to persist data:

- `sonarqube_data`: SonarQube data
- `sonarqube_extensions`: SonarQube extensions
- `sonarqube_logs`: SonarQube logs
- `postgresql_data`: PostgreSQL data

## Security Best Practices

1. **Change default credentials**: After first login, immediately change the default admin password

2. **Use strong passwords**: Set strong passwords for both SonarQube and PostgreSQL

3. **Restrict network access**: Consider using a reverse proxy with HTTPS for production environments

4. **Regular backups**: Set up regular backups of the PostgreSQL database

5. **Update regularly**: Keep SonarQube and PostgreSQL images updated to the latest versions

## Usage

### Analyzing Projects

1. Create a new project in the SonarQube web interface

2. Generate a token for authentication

3. Run analysis using your build tool with the SonarQube plugin:

   #### Maven
   ```bash
   mvn sonar:sonar \
     -Dsonar.projectKey=my-project \
     -Dsonar.host.url=http://localhost:9000 \
     -Dsonar.login=YOUR_GENERATED_TOKEN
   ```

   #### Gradle
   ```bash
   ./gradlew sonarqube \
     -Dsonar.projectKey=my-project \
     -Dsonar.host.url=http://localhost:9000 \
     -Dsonar.login=YOUR_GENERATED_TOKEN
   ```

   #### JavaScript/TypeScript (using SonarScanner)
   ```bash
   sonar-scanner \
     -Dsonar.projectKey=my-project \
     -Dsonar.sources=. \
     -Dsonar.host.url=http://localhost:9000 \
     -Dsonar.login=YOUR_GENERATED_TOKEN
   ```

## Maintenance

### Stopping SonarQube

```bash
docker-compose down
```

### Upgrading SonarQube

1. Update the SonarQube image version in `docker-compose.yml`
2. Run:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Backup and Restore

#### Backup

```bash
docker exec sonarqube_db pg_dump -U sonar sonar > sonarqube_backup.sql
```

#### Restore

```bash
cat sonarqube_backup.sql | docker exec -i sonarqube_db psql -U sonar -d sonar
```

## Troubleshooting

### Common Issues

1. **SonarQube fails to start**: Check if the system requirements are met, especially memory settings

2. **Database connection issues**: Verify PostgreSQL is running and credentials are correct

3. **Permission problems**: Ensure Docker has proper permissions to mount volumes

### Logs

To view SonarQube logs:

```bash
docker-compose logs -f sonarqube
```

To view PostgreSQL logs:

```bash
docker-compose logs -f db
```

## License

SonarQube is licensed under the GNU Lesser GPL License.