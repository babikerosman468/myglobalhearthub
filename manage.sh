#!/data/data/com.termux/files/usr/bin/bash

APP_FILE="server.js"
PORT=3000

NODE_PID_FILE="node.pid"
MYSQL_PID_FILE="mariadb.pid"

# Correct Termux MariaDB data directory
MYSQL_DATA_DIR="$PREFIX/var/lib/mysql"
MYSQL_LOG="mariadb.log"

# --------------------------------------------------
# MariaDB helpers
# --------------------------------------------------

function mariadb_running() {
  mariadb-admin -u root ping >/dev/null 2>&1
}

function get_mariadb_pid() {
  pgrep -f "mariadbd.*$MYSQL_DATA_DIR" | head -n 1
}

function start_mariadb() {
  echo "🔵 Starting MariaDB..."

  if mariadb_running; then
    MARIADB_PID=$(get_mariadb_pid)

    if [ -n "$MARIADB_PID" ]; then
      echo "✅ MariaDB already running with PID $MARIADB_PID"
      echo "$MARIADB_PID" > "$MYSQL_PID_FILE"
    else
      echo "✅ MariaDB is already running"
    fi

    return 0
  fi

  echo "🔄 Starting MariaDB..."

  if command -v mariadbd-safe >/dev/null 2>&1; then
    mariadbd-safe \
      --datadir="$MYSQL_DATA_DIR" \
      > "$MYSQL_LOG" 2>&1 &
  elif command -v mysqld_safe >/dev/null 2>&1; then
    mysqld_safe \
      --datadir="$MYSQL_DATA_DIR" \
      > "$MYSQL_LOG" 2>&1 &
  else
    echo "❌ MariaDB safe-start command not found."
    return 1
  fi

  echo "⏳ Waiting for MariaDB..."

  for i in {1..15}; do
    if mariadb_running; then
      MARIADB_PID=$(get_mariadb_pid)

      if [ -n "$MARIADB_PID" ]; then
        echo "$MARIADB_PID" > "$MYSQL_PID_FILE"
        echo "🔗 MariaDB started with PID $MARIADB_PID"
      else
        echo "✅ MariaDB started"
      fi

      return 0
    fi

    sleep 1
  done

  echo "❌ MariaDB failed to start."
  echo "📄 Check $MYSQL_LOG"
  return 1
}

function stop_mariadb() {
  echo "🛑 Stopping MariaDB..."

  if mariadb_running; then
    mariadb-admin -u root shutdown >/dev/null 2>&1

    sleep 2

    if mariadb_running; then
      echo "⚠️ MariaDB did not stop cleanly."
      return 1
    else
      echo "✅ MariaDB stopped."
    fi
  else
    echo "ℹ️ MariaDB is not running."
  fi

  rm -f "$MYSQL_PID_FILE"
}

# --------------------------------------------------
# Node.js
# --------------------------------------------------

function start_node() {
  echo "🟢 Starting Node.js server ($APP_FILE) on port $PORT..."

  if [ -f "$NODE_PID_FILE" ]; then
    OLD_PID=$(cat "$NODE_PID_FILE")

    if ps -p "$OLD_PID" >/dev/null 2>&1; then
      echo "✅ Node.js already running with PID $OLD_PID"
      return 0
    fi

    rm -f "$NODE_PID_FILE"
  fi

  # Remove stale exported DB variables.
  # This ensures dotenv loads the correct .env values.
  env -u DB_HOST \
      -u DB_USER \
      -u DB_PASS \
      -u DB_NAME \
      node "$APP_FILE" > node.log 2>&1 &

  NODE_PID=$!

  sleep 2

  if ps -p "$NODE_PID" >/dev/null 2>&1; then
    echo "$NODE_PID" > "$NODE_PID_FILE"
    echo "🔗 Node.js server started with PID $NODE_PID"
    echo "🌐 Opening browser at http://127.0.0.1:$PORT ..."

    am start \
      -a android.intent.action.VIEW \
      -d "http://127.0.0.1:$PORT" \
      >/dev/null 2>&1
  else
    echo "❌ Failed to start Node.js server."
    echo "📄 Check node.log"
    return 1
  fi
}

function stop_node() {
  echo "🛑 Stopping Node.js..."

  if [ -f "$NODE_PID_FILE" ]; then
    PID=$(cat "$NODE_PID_FILE")

    if ps -p "$PID" >/dev/null 2>&1; then
      kill "$PID"
      sleep 1

      if ps -p "$PID" >/dev/null 2>&1; then
        kill -9 "$PID"
      fi

      echo "✅ Node.js server stopped."
    else
      echo "ℹ️ Node.js process is not running."
    fi

    rm -f "$NODE_PID_FILE"
  else
    echo "ℹ️ No Node.js PID file."
  fi
}

# --------------------------------------------------
# Commands
# --------------------------------------------------

function start() {
  start_mariadb || return 1

  start_node || return 1

  echo ""
  echo "✅ MyGlobalHeartHub is running."
  echo "🌐 http://127.0.0.1:$PORT"
}

function stop() {
  stop_node
  stop_mariadb
}

function status() {
  echo "========================================"
  echo " MyGlobalHeartHub STATUS"
  echo "========================================"

  echo ""
  echo "MariaDB:"

  if mariadb_running; then
    MARIADB_PID=$(get_mariadb_pid)

    if [ -n "$MARIADB_PID" ]; then
      echo "✅ Running — PID $MARIADB_PID"
    else
      echo "✅ Running"
    fi
  else
    echo "❌ Not running"
  fi

  echo ""
  echo "Node.js:"

  if [ -f "$NODE_PID_FILE" ]; then
    PID=$(cat "$NODE_PID_FILE")

    if ps -p "$PID" >/dev/null 2>&1; then
      echo "✅ Running — PID $PID"
    else
      echo "❌ PID file exists but process is not running"
    fi
  else
    echo "❌ Not running"
  fi

  echo ""
  echo "URL:"
  echo "http://127.0.0.1:$PORT"
}

function fullstop() {
  echo "🔒 Full stop..."
  stop
  echo "✅ All MyGlobalHeartHub services stopped."
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  fullstop)
    fullstop
    ;;
  *)
    echo "Usage: $0 {start|stop|status|fullstop}"
    ;;
esac
