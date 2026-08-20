# 🌍 MyHeartHub

**MyHeartHub** is a Node.js and MariaDB project running in Termux.

## 📂 Project Structure

- `server.js` — Main Node.js server
- `structure/` — SQL files (e.g., `create_members_table.sql`)
- `public/` — Static files
- `views/` — Templates
- `package.json` — Node dependencies
- `manage.sh` — Control script for starting/stopping Node.js & MariaDB

## 🚀 Usage

```bash
chmod +x manage.sh

# Start services
./manage.sh start

# Check status
./manage.sh status

# Stop services
./manage.sh stop

# Stop all and cleanup stale processes
./manage.sh fullstop

🗂️ Backup

Run the provided backup.sh to zip your entire project safely.


