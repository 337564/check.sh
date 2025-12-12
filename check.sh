#!/bin/bash

# ==========================
# Colors
# ==========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================
# Usage Function
# ==========================
usage() {
    echo "Usage:   $0 [-p prefixes] [-m mode]"
    echo "Example: $0 -p p,l,gg,k -m port"
    echo ""
    echo "Options:"
    echo "  -p prefixes  Comma-separated list of hostname prefixes."
    echo "               Default: p    Example: -p p,l,gg,k"
    echo "  -m mode      Mode of operation: ping (default) or port"
    echo "               - ping : Sends ICMP ping requests"
    echo "               - port : Checks if port 5900 is open. Needs nmap! (Uses nc command.)"
    echo "  -h           Displays this help message."
    exit 1
}

# ==========================
# Default Variables
# ==========================
prefixes=("p")
mode="ping"
declare -A successful_hosts

# ==========================
# Parse Command-Line Options
# ==========================
while getopts ":p:m:h" opt; do
  case ${opt} in
    p )
      IFS=',' read -r -a prefixes <<< "$OPTARG"
      ;;
    m )
      if [[ "$OPTARG" == "ping" || "$OPTARG" == "port" ]]; then
        mode="$OPTARG"
      else
        echo -e "${RED}Invalid mode: $OPTARG${NC}"
        usage
      fi
      ;;
    h )
      usage
      ;;
    \? )
      echo -e "${RED}Invalid Option: -$OPTARG${NC}" 1>&2
      usage
      ;;
    : )
      echo -e "${RED}Option -$OPTARG requires an argument.${NC}" 1>&2
      usage
      ;;
  esac
done
shift $((OPTIND -1))

# ==========================
# Handle Ctrl + C (SIGINT)
# ==========================
trap 'echo -e "\n${YELLOW}Script interrupted by user. Exiting...${NC}"; exit 0' SIGINT

# ==========================
# Function to Ping Host
# ==========================
ping_host() {
    local host=$1
    echo -ne "\r${YELLOW}Checking: $host${NC}"
    if timeout 1 ping -W 1 -c 1 "$host" &>/dev/null; then
        successful_hosts[$host]="ping successful"
        echo -e "\r${GREEN}✓ Success: $host (ping)${NC}"
        return 0
    fi
    return 1
}

# ==========================
# Function to Check Port 5900
# ==========================
check_port() {
    local host=$1
    echo -ne "\r${YELLOW}Checking: $host${NC}"
    if nc -z -w 1 "$host" 5900 &>/dev/null; then
        successful_hosts[$host]="port 5900 open"
        echo -e "\r${GREEN}✓ Success: $host (port 5900)${NC}"
        return 0
    fi
    return 1
}

# ==========================
# Main Loop
# ==========================
echo -e "${YELLOW}Starting checks...${NC}"

for prefix in "${prefixes[@]}"; do
    for i in {0..30}; do
        host="${prefix}${i}.iem.pw.edu.pl"
        if [ "$mode" == "ping" ]; then
            ping_host "$host"
        elif [ "$mode" == "port" ]; then
            check_port "$host"
        fi
    done
done

# Clear the status line
echo -ne "\r\033[K"
