#!/bin/bash

# Configuration
WEATHER_LOCATION="Leeds, UK"  # Change this to any location

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
    
    for frame in {1..10}; do
        printf "\r${CYAN}"
        for (( i=0; i<width; i++ )); do
            printf "%s" "${chars:$((($i + $frame) % 7)):1}"
        done
        printf "${NC}"
        sleep 0.1
    done
    echo
}

# Function to display animated loading bar
# Usage: loading_bar "Loading message..."
loading_bar() {
    local message="$1"
    local bar_length=${2:-50}  # Default to 50 chars if not specified
    local delay=${3:-0.02}     # Default to 0.02s delay if not specified
    
    echo -e "${YELLOW}${BOLD}${message}${NC}"
    printf "${CYAN}["
    for i in $(seq 1 $bar_length); do
        printf "${GREEN}█${NC}"
        sleep $delay
    done
    echo -e "${CYAN}]${NC}"
    echo
}

# Function to get weather and display ASCII art
show_weather() {
    local location="${WEATHER_LOCATION}"
    echo -e "${CYAN}${BOLD}🌍 Weather in ${location}${NC}"
    
    # First, geocode the location to get lat/lon using Nominatim (free OpenStreetMap service)
    local encoded_location=$(echo "$location" | sed 's/ /%20/g')
    local geo_data=$(curl -s --max-time 3 "https://nominatim.openstreetmap.org/search?q=${encoded_location}&format=json&limit=1" 2>/dev/null)
    
    local latitude=""
    local longitude=""
    
    if [ -n "$geo_data" ] && echo "$geo_data" | grep -q "lat"; then
        latitude=$(echo "$geo_data" | grep -oE '"lat":"[0-9.-]+"' | head -1 | cut -d'"' -f4)
        longitude=$(echo "$geo_data" | grep -oE '"lon":"[0-9.-]+"' | head -1 | cut -d'"' -f4)
    fi
    
    # Fallback to Leeds coordinates if geocoding fails
    if [ -z "$latitude" ] || [ -z "$longitude" ]; then
        latitude="53.8008"
        longitude="-1.5491"
    fi
    
    # Use open-meteo.com (free, no API key required)
    local weather_data=$(curl -s --max-time 3 "https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current_weather=true" 2>/dev/null)
    
    if [ -n "$weather_data" ] && echo "$weather_data" | grep -q "current_weather"; then
        # Parse temperature, weather code, wind speed and direction (handle decimal numbers)
        local temp=$(echo "$weather_data" | grep -oE '"temperature":[0-9.-]+' | head -1 | cut -d':' -f2)
        local weathercode=$(echo "$weather_data" | grep -oE '"weathercode":[0-9]+' | tail -1 | cut -d':' -f2)
        local windspeed=$(echo "$weather_data" | grep -oE '"windspeed":[0-9.-]+' | tail -1 | cut -d':' -f2)
        local winddirection=$(echo "$weather_data" | grep -oE '"winddirection":[0-9.-]+' | tail -1 | cut -d':' -f2)
        
        # Round temperature and wind speed
        temp=$(printf "%.0f" "$temp" 2>/dev/null || echo "$temp")
        windspeed=$(printf "%.0f" "$windspeed" 2>/dev/null || echo "$windspeed")
        
        # Convert wind direction to compass direction
        local wind_dir=""
        if [ -n "$winddirection" ]; then
            local dir=$(printf "%.0f" "$winddirection" 2>/dev/null)
            if [ $dir -ge 337 ] || [ $dir -lt 23 ]; then
                wind_dir="N"
            elif [ $dir -ge 23 ] && [ $dir -lt 68 ]; then
                wind_dir="NE"
            elif [ $dir -ge 68 ] && [ $dir -lt 113 ]; then
                wind_dir="E"
            elif [ $dir -ge 113 ] && [ $dir -lt 158 ]; then
                wind_dir="SE"
            elif [ $dir -ge 158 ] && [ $dir -lt 203 ]; then
                wind_dir="S"
            elif [ $dir -ge 203 ] && [ $dir -lt 248 ]; then
                wind_dir="SW"
            elif [ $dir -ge 248 ] && [ $dir -lt 293 ]; then
                wind_dir="W"
            elif [ $dir -ge 293 ] && [ $dir -lt 337 ]; then
                wind_dir="NW"
            fi
        fi
        
        # WMO Weather interpretation codes
        # 0: Clear sky, 1-3: Mainly clear/partly cloudy/overcast
        # 45,48: Fog, 51-57: Drizzle, 61-67: Rain, 71-77: Snow
        # 80-82: Rain showers, 85-86: Snow showers, 95-99: Thunderstorm
        
        case "$weathercode" in
            0)
                # Clear sky
                echo -e "${YELLOW}"
                echo "    \\   /    "
                echo "     .-.     "
                echo "  ― (   ) ―  "
                echo "     \`-'     "
                echo "    /   \\    "
                condition="Clear"
                ;;
            1|2|3)
                # Mainly clear to overcast
                echo -e "${WHITE}"
                echo "             "
                echo "     .--.    "
                echo "  .-(    ).  "
                echo " (___.__)__) "
                echo "             "
                condition="Cloudy"
                ;;
            45|48)
                # Fog
                echo -e "${WHITE}"
                echo "             "
                echo " _ - _ - _ - "
                echo "  _ - _ - _  "
                echo " _ - _ - _ - "
                echo "             "
                condition="Foggy"
                ;;
            51|53|55|56|57|61|63|65|66|67|80|81|82)
                # Rain/Drizzle
                echo -e "${BLUE}"
                echo "     .-.     "
                echo "    (   ).   "
                echo "   (___(__)  "
                echo "    ʻ ʻ ʻ ʻ  "
                echo "   ʻ ʻ ʻ ʻ   "
                condition="Rainy"
                ;;
            71|73|75|77|85|86)
                # Snow
                echo -e "${WHITE}"
                echo "     .-.     "
                echo "    (   ).   "
                echo "   (___(__)  "
                echo "    *  *  *  "
                echo "   *  *  *   "
                condition="Snowy"
                ;;
            95|96|99)
                # Thunderstorm
                echo -e "${YELLOW}"
                echo "     .-.     "
                echo "    (   ).   "
                echo "   (___(__)  "
                echo "    ⚡ ʻ ⚡   "
                echo "   ʻ ⚡ ʻ    "
                condition="Stormy"
                ;;
            *)
                # Default
                echo -e "${CYAN}"
                echo "     .-.     "
                echo "    (   ).   "
                echo "   (___(__)  "
                echo "             "
                condition="Unknown"
                ;;
        esac
        echo -e "${NC}"
        echo -e "${WHITE}${condition} ${temp}°C${NC}"
        if [ -n "$windspeed" ] && [ -n "$wind_dir" ]; then
            echo -e "${CYAN}💨 Wind: ${windspeed} km/h ${wind_dir}${NC}"
        fi
    else
        # Fallback - show a nice cloudy Leeds default (it's usually cloudy there! 😄)
        echo -e "${WHITE}"
        echo "             "
        echo "     .--.    "
        echo "  .-(    ).  "
        echo " (___.__)__) "
        echo "             "
        echo -e "${NC}"
        echo -e "${CYAN}Typical Leeds weather ☁️  (API unavailable)${NC}"
    fi
    echo
}

# Function to show NHS Notify mascot - a messenger pigeon!
show_mascot() {
    local mascots=(
        # Pigeon with letter
        "${CYAN}
       __     
   ___( o)>   NHS Notify Messenger!
   \\ <_. )   Delivering notifications
    \`---'    at the speed of flight! 📬
"
        # Pigeon sitting
        "${BLUE}
      (o>     
   __//\\\\__   Ready to send those
   \`-|_|-'   important messages! 🕊️
"
        # Pigeon with NHS badge
        "${PURPLE}
    ___      
   (o o)     NHS Notify Pigeon:
   |)_(|     Your trusted notification
    '-'      delivery service! 💙
"
    )
    
    # Pick a random mascot
    local random_mascot=${mascots[$RANDOM % ${#mascots[@]}]}
    echo -e "${random_mascot}${NC}"
}

# Helper function to count emojis in text
count_emojis() {
    local text="$1"
    local count=0
    
    # List of emojis used in this script (each should be counted)
    # Note: Some emojis like 🖥️ and ⏱️ include variation selectors which are handled separately
    local emojis="🐳 📅 ⏰ 👤 🖥 📂 🧠 💾 ⚡ ⏱ 🚀 🌟 💡 🔍 📦 🔧 📝 🔐 🔥 🎯 💎 🏆 🎨 ⭐ 🌿 ⚠ 🎉 💪 🐍 🐙 ☁ 🛠 📊 🔄 📚 🟢 💭 🌅 ☀ 🌙 ☕"
    
    # Count each emoji type (without variation selectors in the search pattern)
    for emoji in $emojis; do
        local found=$(echo "$text" | grep -o "$emoji" 2>/dev/null | wc -l)
        count=$((count + found))
    done
    
    echo "$count"
}

# Helper function to count variation selectors (zero-width characters that add to string length but not display)
count_variation_selectors() {
    local text="$1"
    # Variation Selector-16 (U+FE0F) appears after some emojis like 🖥️ and ⏱️
    # These are counted by bash as characters but display as zero width
    # We need to subtract them from the length since they don't display
    local vs_count=$(echo "$text" | grep -o $'\uFE0F' 2>/dev/null | wc -l)
    echo "$vs_count"
}

# Standard boxing function - creates a box around content
# Usage: draw_box <border_color> <title> <box_width> [line1] [line2] ...
draw_box() {
    local border_color="$1"
    local title="$2"
    local box_width="$3"
    shift 3
    local lines=("$@")
    
    # Calculate internal width (box_width minus borders and padding: "║ " + " ║")
    local internal_width=$((box_width - 4))
    
    # Top border
    echo -e "${border_color}╔$(printf '═%.0s' $(seq 1 $((box_width - 2))))╗${NC}"
    
    # Title (if provided)
    if [ -n "$title" ]; then
        # Strip colors and measure
        local title_clean=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        # Count actual character positions (bash's ${#var} counts multi-byte chars correctly)
        local title_len=${#title_clean}
        # Count emojis (each takes 2 display columns but bash counts as 1)
        local title_emoji_count=$(count_emojis "$title_clean")
        # Count variation selectors (counted as 1 char by bash but 0 width display)
        local title_vs_count=$(count_variation_selectors "$title_clean")
        # Display width: emojis with VS are already counted as 2 by bash and display as 2
        # So: display = bash_length + (emojis without VS) - (VS count * 2, since they add to bash count but not display and block the emoji +1)
        local display_adjustment=$((title_emoji_count - title_vs_count - title_vs_count))
        local title_display=$((title_len + display_adjustment))
        
        local title_padding=$(( (internal_width - title_display) / 2 ))
        local title_padding_right=$(( internal_width - title_display - title_padding ))
        printf "${border_color}║${NC} "
        printf "%*s" $title_padding ""
        echo -ne "$title"
        printf "%*s" $title_padding_right ""
        echo -e " ${border_color}║${NC}"
        echo -e "${border_color}╠$(printf '═%.0s' $(seq 1 $((box_width - 2))))╣${NC}"
    fi
    
    # Content lines
    for line in "${lines[@]}"; do
        # Strip ANSI codes
        local line_clean=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        # Count characters as bash sees them
        local line_len=${#line_clean}
        # Count emojis (each needs +1 for double-width display)
        local line_emoji_count=$(count_emojis "$line_clean")
        # Count variation selectors (need to subtract since they don't display)
        local line_vs_count=$(count_variation_selectors "$line_clean")
        
        # Special handling: emojis WITH variation selectors don't need the +1
        # because bash already counts them as 2 (emoji + VS), and they display as 2
        # So for lines with VS, don't add the emoji count
        # Display width = bash_length + emoji_count - (vs_count + vs_count)
        # Actually: if VS exists, that emoji shouldn't be counted in emoji_count adjustment
        local display_adjustment=$((line_emoji_count - line_vs_count - line_vs_count))
        local actual_display_width=$((line_len + display_adjustment))
        
        local padding_needed=$((internal_width - actual_display_width))
        
        # Ensure padding is not negative
        if [ $padding_needed -lt 0 ]; then
            padding_needed=0
        fi
        
        printf "${border_color}║${NC} "
        echo -ne "$line"
        printf "%*s" $padding_needed ""
        echo -e " ${border_color}║${NC}"
    done
    
    # Bottom border
    echo -e "${border_color}╚$(printf '═%.0s' $(seq 1 $((box_width - 2))))╝${NC}"
}

# Clear screen and start the show
#clear

# Animated border
animate_border

echo -e "${BOLD}${GREEN}"
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

animate_border

# Animated loading bar
loading_bar "Initializing NHS Notify Development Environment..."

# System info with style
container_info=(
    "${CYAN}🐳 Container: NHS Notify Development Environment${NC}"
    "${CYAN}📅 Date:      $(date +'%A, %B %d, %Y')${NC}"
    "${CYAN}⏰ Time:      $(date +'%H:%M:%S %Z')${NC}"
    "${CYAN}👤 User:      $(whoami)${NC}"
    "${CYAN}🖥️  Host:      $(hostname)${NC}"
    "${CYAN}📂 Workspace: $(pwd)${NC}"
)

draw_box "${PURPLE}${BOLD}" "${BOLD}${WHITE}CONTAINER INFORMATION${NC}" 80 "${container_info[@]}"
echo

loading_bar "Getting weather..."
# Show weather
show_weather

# Show wttr.in output
echo -e "${CYAN}${BOLD}🌤️  wttr.in Weather Report${NC}"
encoded_location=$(echo "$WEATHER_LOCATION" | sed 's/ /+/g')
wttr_output=$(curl -s --max-time 5 "wttr.in/${encoded_location}?1" 2>/dev/null)
if [ -n "$wttr_output" ]; then
    echo "$wttr_output"
else
    echo -e "${YELLOW}⚠️  wttr.in service unavailable${NC}"
fi
echo

# Feature showcase
echo -e "${GREEN}${BOLD}🚀 READY TO DEVELOP WITH:${NC}"
echo
echo -e "${YELLOW}  🟢 Node.js 22.21.0${NC}      - JavaScript/TypeScript development with NVM"
echo -e "${YELLOW}  🐍 Python${NC}               - Python development tools"
echo -e "${YELLOW}  � Go 1.25.3${NC}            - Go development environment"
echo -e "${YELLOW}  💎 Ruby 3.4.7${NC}           - Ruby development tools"
echo -e "${YELLOW}  🐙 Git + GitHub CLI${NC}     - Version control with gh CLI tools"
echo -e "${YELLOW}  🐳 Docker-in-Docker${NC}     - Container management & Docker Compose"
echo -e "${YELLOW}  ☁️  AWS CLI 2.31.18${NC}      - Amazon Web Services toolkit"
echo -e "${YELLOW}  📦 ASDF Version Manager${NC}  - Multi-language version management"
echo -e "${YELLOW}  � Build Essential${NC}      - C/C++ compilation tools"
echo -e "${YELLOW}  🛠️  Oh My Zsh${NC}            - Enhanced shell with plugins (git, ssh-agent, terraform)"
echo -e "${YELLOW}  📝 VS Code Extensions${NC}    - 30+ productivity extensions pre-installed"
echo -e "${YELLOW}  � ESLint & Prettier${NC}     - Code formatting and linting"
echo -e "${YELLOW}  📊 Terraform Support${NC}     - Infrastructure as Code tools"
echo -e "${YELLOW}  🔐 GPG & SSH${NC}             - Security and authentication tools"
echo -e "${YELLOW}  📋 Make & Scripts${NC}        - NHS Notify repository templates & automation"
echo

# Quick Health Check & Stats
memory_info=$(free -h | awk 'NR==2{printf "Memory: %s/%s (%.1f%%)", $3,$2,$3*100/$2 }')
disk_info=$(df -h / | awk 'NR==2{printf "Disk: %s/%s (%s used)", $3,$2,$5}')
cpu_info="CPU Cores: $(nproc)"
uptime_raw=$(uptime -p | sed 's/up //')
uptime_info="Container uptime: ${uptime_raw}"

health_check=(
    "${GREEN}🧠 ${memory_info}${NC}"
    "${GREEN}💾 ${disk_info}${NC}"
    "${GREEN}⚡ ${cpu_info}${NC}"
    "${GREEN}⏱️  ${uptime_info}${NC}"
)

draw_box "${CYAN}" "${CYAN}${BOLD}📊 QUICK HEALTH CHECK${NC}" 80 "${health_check[@]}"
echo

# Fun message with typewriter effect
echo -e "${BOLD}${CYAN}"
typewriter "💡 Tip: This environment is optimized for NHS Notify development!"
echo -e "${NC}"
echo

# Development Tips
dev_tips=(
    "💡 Tip: Use 'make help' to see available project commands!"
    "🔍 Tip: Run 'gh repo view' to quickly check the current repository status!"
    "🐳 Tip: Use 'docker ps' to see running containers in this environment!"
    "📦 Tip: Run 'asdf list' to see all installed language versions!"
    "🔧 Tip: Type 'code .' to open the current directory in VS Code!"
    "🚀 Tip: Use 'npm run dev' or 'make dev' to start development servers!"
    "🌟 Tip: Press Ctrl+\` to open/close the integrated terminal!"
    "📝 Tip: Use 'git log --oneline -10' for a clean commit history view!"
    "🔐 Tip: Run 'gh auth status' to check your GitHub authentication!"
    "⚡ Tip: Use 'terraform --version' to verify Terraform installation!"
)

random_tip=${dev_tips[$RANDOM % ${#dev_tips[@]}]}
echo -e "${GREEN}${random_tip}${NC}"
echo

# Show NHS Notify mascot
show_mascot

# Quick Commands Reference
echo -e "${PURPLE}${BOLD}⚡ QUICK COMMANDS${NC}"
echo -e "${YELLOW}  make help${NC}          - Show project-specific commands"
echo -e "${YELLOW}  gh repo view${NC}       - View current repository info"
echo -e "${YELLOW}  docker ps${NC}          - List running containers"
echo -e "${YELLOW}  asdf current${NC}       - Show current language versions"
echo -e "${YELLOW}  aws --version${NC}      - Verify AWS CLI installation"
echo

# Time-based greeting with fun elements
current_hour=$(date +%H)
if [ $current_hour -lt 12 ]; then
    greeting="🌅 Good morning"
    mood_emoji="☕"
elif [ $current_hour -lt 17 ]; then
    greeting="☀️ Good afternoon" 
    mood_emoji="🚀"
else
    greeting="🌙 Good evening"
    mood_emoji="🌟"
fi

echo -e "${BOLD}${WHITE}${greeting}, $(whoami)! ${mood_emoji} Ready to build something amazing?${NC}"
echo

# Fun coding mood indicator
coding_moods=(
    "🔥 You're on fire today!"
    "⚡ High voltage coding mode activated!"
    "🎯 Laser-focused and ready to ship!"
    "🧠 Big brain energy detected!"
    "💎 Time to create something brilliant!"
    "🚀 Launch sequence initiated!"
    "🎨 Ready to paint some beautiful code!"
    "🏆 Champion developer mode: ENABLED!"
)

random_mood=${coding_moods[$RANDOM % ${#coding_moods[@]}]}
echo -e "${BOLD}${PURPLE}${random_mood}${NC}"
echo

# Motivational quote
quotes=(
    "\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs"
    "\"The best time to plant a tree was 20 years ago. The second best time is now.\" - Chinese Proverb"
    "\"Code is like humor. When you have to explain it, it's bad.\" - Cory House"
    "\"First, solve the problem. Then, write the code.\" - John Johnson"
    "\"Experience is the name everyone gives to their mistakes.\" - Oscar Wilde"
    "\"Any fool can write code that a computer can understand. Good programmers write code that humans can understand.\" - Martin Fowler"
    "\"The only way to go fast is to go well.\" - Robert C. Martin"
    "\"Talk is cheap. Show me the code.\" - Linus Torvalds"
    "\"Programs must be written for people to read, and only incidentally for machines to execute.\" - Harold Abelson"
    "\"The best error message is the one that never shows up.\" - Thomas Fuchs"
    "\"Simplicity is the ultimate sophistication.\" - Leonardo da Vinci"
    "\"Code never lies, comments sometimes do.\" - Ron Jeffries"
    "\"The most important property of a program is whether it accomplishes the intention of its user.\" - C.A.R. Hoare"
    "\"Debugging is twice as hard as writing the code in the first place.\" - Brian Kernighan"
    "\"Good code is its own best documentation.\" - Steve McConnell"
    "\"Make it work, make it right, make it fast.\" - Kent Beck"
    "\"The function of good software is to make the complex appear to be simple.\" - Grady Booch"
    "\"There are only two hard things in Computer Science: cache invalidation and naming things.\" - Phil Karlton"
    "\"Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away.\" - Antoine de Saint-Exupéry"
    "\"Programming is not about typing, it's about thinking.\" - Rich Hickey"
)

random_quote=${quotes[$RANDOM % ${#quotes[@]}]}
echo -e "${ITALIC}${BLUE}💭 ${random_quote}${NC}"
echo

loading_bar "Getting achievements..."

# Fun Achievement System
echo -e "${YELLOW}${BOLD}🏆 DEVELOPER ACHIEVEMENTS UNLOCKED${NC}"

# Check for various files/conditions and award achievements
achievements=()

if [ -f "package.json" ]; then
    achievements+=("📦 Node.js Navigator - package.json detected!")
fi

if [ -f "Dockerfile" ]; then
    achievements+=("🐳 Container Captain - Dockerfile found!")
fi

if [ -f "terraform.tf" ] || [ -f "main.tf" ]; then
    achievements+=("🏗️ Infrastructure Architect - Terraform files detected!")
fi

if [ -f "Makefile" ]; then
    achievements+=("⚙️ Automation Expert - Makefile ready to roll!")
fi

if [ -d ".git" ]; then
    achievements+=("🔄 Version Control Virtuoso - Git repository active!")
fi

if [ -f "README.md" ]; then
    achievements+=("📚 Documentation Dynamo - README.md present!")
fi

# Always available achievements
achievements+=("🎯 Environment Expert - NHS Notify devcontainer loaded!")
achievements+=("⚡ Multi-language Master - Node.js, Python, Go & Ruby ready!")



# Display random achievements (max 3)
if [ ${#achievements[@]} -gt 0 ]; then
    # Shuffle and take up to 3 achievements
    for i in $(shuf -i 0-$((${#achievements[@]}-1)) | head -3); do
        echo -e "${CYAN}  ${achievements[$i]}${NC}"
    done
else
    echo -e "${CYAN}  🚀 Ready to unlock your first achievement!${NC}"
fi
echo



# Fun container stats
total_packages=$(dpkg -l | wc -l)
vs_code_extensions="30+"

echo -e "${BOLD}${CYAN}📊 Container loaded with ${total_packages} packages & ${vs_code_extensions} VS Code extensions!${NC}"
echo -e "${BOLD}${GREEN}🎉 Welcome to your NHS Notify development journey! Happy coding! 🎉${NC}"

# Random encouraging message
encouraging_messages=(
    "🌟 Every expert was once a beginner. Every pro was once an amateur!"
    "💪 Great things never come from comfort zones!"
    "🎯 Code with purpose, debug with patience, deploy with confidence!"
    "🚀 Today's bugs are tomorrow's features (just kidding, fix them)!"
    "🔥 Write code that future you will thank present you for!"
    "⭐ The best code is code that solves real problems!"
)

random_message=${encouraging_messages[$RANDOM % ${#encouraging_messages[@]}]}
echo -e "${ITALIC}${YELLOW}${random_message}${NC}"
echo

# Show current git branch if in a repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    echo -e "${CYAN}🌿 Current branch: ${BOLD}${current_branch}${NC}"
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes - don't forget to commit them!${NC}"
    fi
fi


echo

# Final animated border
animate_border
