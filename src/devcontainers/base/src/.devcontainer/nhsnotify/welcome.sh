#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print with typewriter effect
typewriter() {
    text="$1"
    delay=${2:-0.03}
    for (( i=0; i<${#text}; i++ )); do
        printf "%s" "${text:$i:1}"
        sleep $delay
    done
}

# Function to create animated border
animate_border() {
    local width=80
    local chars="▓▒░ ░▒▓"
    
    for frame in {1..3}; do
        printf "\r${CYAN}"
        for (( i=0; i<width; i++ )); do
            printf "%s" "${chars:$((($i + $frame) % 7)):1}"
        done
        printf "${NC}"
        sleep 0.1
    done
    echo
}

# Clear screen and start the show
clear

# Animated border
animate_border

echo -e "${BOLD}${BLUE}"
echo "
██████╗ ███████╗██╗   ██╗    ███████╗███╗   ██╗██╗   ██╗██╗██████╗  ██████╗ ███╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
██╔══██╗██╔════╝██║   ██║    ██╔════╝████╗  ██║██║   ██║██║██╔══██╗██╔═══██╗████╗  ██║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
██║  ██║█████╗  ██║   ██║    █████╗  ██╔██╗ ██║██║   ██║██║██████╔╝██║   ██║██╔██╗ ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
██║  ██║██╔══╝  ╚██╗ ██╔╝    ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██╔══██╗██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
██████╔╝███████╗ ╚████╔╝     ███████╗██║ ╚████║ ╚████╔╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
╚═════╝ ╚══════╝  ╚═══╝      ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
"
echo -e "${NC}"

# NHS Logo in ASCII
echo -e "${BLUE}${BOLD}"
echo "
          ███╗   ██╗██╗  ██╗███████╗
          ████╗  ██║██║  ██║██╔════╝
          ██╔██╗ ██║███████║███████╗    
          ██║╚██╗██║██╔══██║╚════██║    
          ██║ ╚████║██║  ██║███████║    
          ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝    
"

echo -e "${RED}${BOLD}"
echo "
        ███╗   ██╗ ██████╗ ████████╗██╗███████╗██╗   ██╗
        ████╗  ██║██╔═══██╗╚══██╔══╝██║██╔════╝╚██╗ ██╔╝
        ██╔██╗ ██║██║   ██║   ██║   ██║█████╗   ╚████╔╝ 
        ██║╚██╗██║██║   ██║   ██║   ██║██╔══╝    ╚██╔╝  
        ██║ ╚████║╚██████╔╝   ██║   ██║██║        ██║   
        ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝╚═╝        ╚═╝   
"
echo -e "${NC}"

# Animated loading bar
echo -e "${YELLOW}${BOLD}Initializing NHS Notify Development Environment...${NC}"
echo -e "${CYAN}["
for i in {1..50}; do
    printf "${GREEN}█${NC}"
    sleep 0.02
done
echo -e "${CYAN}]${NC}"
echo

# System info with style
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║${NC}                            ${BOLD}${WHITE}CONTAINER INFORMATION${NC}                            ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}🐳 Container:${NC} NHS Notify Development Environment                      ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}📅 Date:${NC}      $(date +'%A, %B %d, %Y')                                ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}⏰ Time:${NC}      $(date +'%H:%M:%S %Z')                                     ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}👤 User:${NC}      $(whoami)                                                    ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}🖥️  Host:${NC}      $(hostname)                                              ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}║${NC} ${CYAN}📂 Workspace:${NC} $(pwd)                           ${PURPLE}${BOLD}║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo

# Feature showcase
echo -e "${GREEN}${BOLD}🚀 READY TO DEVELOP WITH:${NC}"
echo
echo -e "${YELLOW}  ✨ Node.js & npm${NC}       - JavaScript/TypeScript development"
echo -e "${YELLOW}  🐍 Python & pip${NC}       - Python development tools"
echo -e "${YELLOW}  🐙 Git${NC}                - Version control"
echo -e "${YELLOW}  🐳 Docker${NC}             - Container management"
echo -e "${YELLOW}  📝 VS Code Extensions${NC} - Enhanced development experience"
echo -e "${YELLOW}  🔧 ESLint & Prettier${NC}  - Code formatting and linting"
echo

# Fun message with typewriter effect
echo -e "${BOLD}${CYAN}"
typewriter "💡 Tip: This environment is optimized for NHS Notify development!"
echo -e "${NC}"
echo

# Motivational quote
quotes=(
    "\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs"
    "\"The best time to plant a tree was 20 years ago. The second best time is now.\" - Chinese Proverb"
    "\"Code is like humor. When you have to explain it, it's bad.\" - Cory House"
    "\"First, solve the problem. Then, write the code.\" - John Johnson"
    "\"Experience is the name everyone gives to their mistakes.\" - Oscar Wilde"
)

random_quote=${quotes[$RANDOM % ${#quotes[@]}]}
echo -e "${ITALIC}${BLUE}💭 ${random_quote}${NC}"
echo

# Final animated border
animate_border

echo -e "${BOLD}${GREEN}🎉 Welcome to your NHS Notify development journey! Happy coding! 🎉${NC}"
echo