#!/data/data/com.termux/files/usr/bin/bash

APP_FILE="server.js"
PORT=3010

NODE_PID_FILE="node.pid"
MYSQL_PID_FILE="mariadb.pid"
MYSQL_DATA_DIR="$HOME/myhearthub/mysql_data"
MYSQL_LOG="mariadb.log"

function cleanup_stale_mariadb() {
  echo "🧹 Checking for stale MariaDB processes..."
  for pid in $(ps aux | grep "[m]ysqld" | awk '{print $2}'); do
    echo "⚠️ Killing stale MariaDB process with PID $pid"
    kill -9 "$pid"
  done
}

function get_mariadb_pid() {
  if [ -f "$MYSQL_DATA_DIR/localhost.pid" ]; then
    cat "$MYSQL_DATA_DIR/localhost.pid"
  else
    pgrep -f "mysqld" | head -n 1
  fi
}

function start() {
  echo "🔍 Checking ports..."
  echo "🔵 Starting MariaDB..."

  if [ -f "$MYSQL_PID_FILE" ]; then
    MARIADB_PID=$(cat "$MYSQL_PID_FILE")
    if ps -p "$MARIADB_PID" > /dev/null 2>&1; then
      echo "✅ MariaDB is already running with PID $MARIADB_PID"
    else
      echo "⚠️ MariaDB PID file exists but process not found. Cleaning up and restarting..."
      cleanup_stale_mariadb
      mysqld_safe --datadir="$MYSQL_DATA_DIR" > "$MYSQL_LOG" 2>&1 &
      sleep 3
      MARIADB_REAL_PID=$(get_mariadb_pid)
      if [ -n "$MARIADB_REAL_PID" ]; then
        echo "$MARIADB_REAL_PID" > "$MYSQL_PID_FILE"
        echo "🔗 MariaDB restarted with PID $MARIADB_REAL_PID"
      else
        echo "❌ Failed to get MariaDB PID."
      fi
    fi
  else
    echo "🔄 Starting MariaDB..."
    cleanup_stale_mariadb
    mysqld_safe --datadir="$MYSQL_DATA_DIR" > "$MYSQL_LOG" 2>&1 &
    sleep 3
    MARIADB_REAL_PID=$(get_mariadb_pid)
    if [ -n "$MARIADB_REAL_PID" ]; then
      echo "$MARIADB_REAL_PID" > "$MYSQL_PID_FILE"
      echo "🔗 MariaDB started with PID $MARIADB_REAL_PID"
    else
      echo "❌ Failed to get MariaDB PID."
    fi
  fi

  echo "🟢 Starting Node.js server ($APP_FILE) on port $PORT..."
  node "$APP_FILE" > node.log 2>&1 &
  NODE_PID=$!
  sleep 1
  if ps -p "$NODE_PID" > /dev/null 2>&1; then
    echo "$NODE_PID" > "$NODE_PID_FILE"
    echo "🔗 Node.js server started with PID $NODE_PID"
    echo "🌐 Opening browser at http://127.0.0.1:$PORT ..."
    am start -a android.intent.action.VIEW -d http://127.0.0.1:$PORT > /dev/null 2>&1
  else
    echo "❌ Failed to start Node.js server."
  fi
}

function stop() {
  echo "🛑 Stopping services..."

  if [ -f "$NODE_PID_FILE" ]; then
    PID=$(cat "$NODE_PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
      kill "$PID"
      echo "✅ Node.js server (PID $PID) stopped."
    else
      echo "⚠️ Node.js PID file exists but process not running."
    fi
    rm -f "$NODE_PID_FILE"
  else
    echo "❌ No Node.js PID file found."
  fi

  if [ -f "$MYSQL_PID_FILE" ]; then
    MARIADB_PID=$(cat "$MYSQL_PID_FILE")
    if ps -p "$MARIADB_PID" > /dev/null 2>&1; then
      kill "$MARIADB_PID"
      echo "✅ MariaDB (PID $MARIADB_PID) stopped."
    else
      echo "⚠️ MariaDB PID file exists but process not running."
    fi
    rm -f "$MYSQL_PID_FILE"
  else
    echo "❌ No MariaDB PID file found."
  fi

  cleanup_stale_mariadb
}

function status() {
  echo "📊 MariaDB status:"
  if [ -f "$MYSQL_PID_FILE" ]; then
    MARIADB_PID=$(cat "$MYSQL_PID_FILE")
    if ps -p "$MARIADB_PID" > /dev/null 2>&1; then
      echo "✅ MariaDB running with PID $MARIADB_PID"
    else
      echo "❌ MariaDB PID file exists but process not running."
    fi
  else
    echo "❌ MariaDB PID file not found."
  fi

  echo "📊 Node.js server status:"
  if [ -f "$NODE_PID_FILE" ]; then
    PID=$(cat "$NODE_PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
      echo "✅ Node.js running with PID $PID"
    else
      echo "❌ Node.js PID file exists but process not running."
    fi
  else
    echo "❌ Node.js is not running."
  fi
}

function fullstop() {
  echo "🔒 Full stop: terminating all known processes..."
  stop
  cleanup_stale_mariadb
}

case "$1" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  fullstop) fullstop ;;
  *)
    echo "Usage: $0 {start|stop|status|fullstop}"
    ;;
esac




