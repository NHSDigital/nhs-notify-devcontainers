#!/bin/bash

echo "GITHUBMONITOR variable is set to: ${GITHUBMONITOR}"
github_monitor="${GITHUBMONITOR:-true}"
if [ "${github_monitor}" != "true" ]; then
    echo "Skipping GitHub monitor script as per configuration"
    exit 0
fi

# GitHub Repository Monitor
# Displays recent commits and open PRs for a list of public GitHub repositories

# Configuration
DEFAULT_COMMIT_COUNT=5
GITHUB_API_BASE="https://api.github.com"

# Dynamic repository discovery configuration
DEFAULT_GITHUB_ORG="NHSDigital"          # Default GitHub organization to search
DEFAULT_REPO_PREFIX="nhs-notify"         # Default repository name prefix to filter by

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# List of repositories to monitor (format: "owner/repo")
# Add your repositories here
REPOSITORIES=(
    "NHSDigital/nhs-notify-repository-template"
    "NHSDigital/nhs-notify-devcontainers"
    # Add more repositories as needed
)

# Function to check if required tools are available
check_dependencies() {
    local missing_tools=()
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install the missing tools and try again."
        return 1
    fi
    
    return 0
}

# Function to fetch repositories from GitHub organization with prefix filter
fetch_repositories_from_org() {
    local org="$1"
    local prefix="$2"
    local repos=()
    local page=1
    local per_page=100
    
    echo -e "${CYAN}Fetching repositories from organization: $org with prefix: $prefix${NC}" >&2
    
    while true; do
        local api_url="$GITHUB_API_BASE/orgs/$org/repos?type=public&per_page=$per_page&page=$page"
        local repos_data
        
        repos_data=$(github_api_request "$api_url")
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to fetch repositories from organization: $org${NC}" >&2
            return 1
        fi
        
        # Check if we got any results
        local repo_count=$(echo "$repos_data" | jq '. | length')
        if [ "$repo_count" -eq 0 ]; then
            break
        fi
        
        # Filter repositories by prefix and add to array
        local filtered_repos
        filtered_repos=$(echo "$repos_data" | jq -r ".[] | select(.name | startswith(\"$prefix\")) | .full_name")
        
        while IFS= read -r repo; do
            if [ -n "$repo" ]; then
                repos+=("$repo")
            fi
        done <<< "$filtered_repos"
        
        # If we got less than per_page results, we're on the last page
        if [ "$repo_count" -lt "$per_page" ]; then
            break
        fi
        
        ((page++))
    done
    
    if [ ${#repos[@]} -eq 0 ]; then
        echo -e "${YELLOW}No repositories found in organization '$org' with prefix '$prefix'${NC}" >&2
        return 1
    fi
    
    echo -e "${GREEN}Found ${#repos[@]} repositories matching prefix '$prefix'${NC}" >&2
    
    # Output the repositories (one per line for easy parsing)
    printf "%s\n" "${repos[@]}"
    return 0
}

# Function to initialize repository list
initialize_repositories() {
    local use_dynamic="$1"
    local github_org="$2"
    local repo_prefix="$3"
    
    if [ "$use_dynamic" = "true" ]; then
        echo -e "${CYAN}Using dynamic repository discovery...${NC}" >&2
        
        local dynamic_repos
        dynamic_repos=$(fetch_repositories_from_org "$github_org" "$repo_prefix")
        
        if [ $? -eq 0 ] && [ -n "$dynamic_repos" ]; then
            # Convert newline-separated list to array
            mapfile -t REPOSITORIES <<< "$dynamic_repos"
            echo -e "${GREEN}Successfully loaded ${#REPOSITORIES[@]} repositories dynamically${NC}" >&2
        else
            echo -e "${YELLOW}Failed to fetch repositories dynamically, falling back to default list${NC}" >&2
            # Keep the default REPOSITORIES array as fallback
        fi
    else
        echo -e "${CYAN}Using configured repository list${NC}" >&2
    fi
}

# Function to make GitHub API request with error handling
github_api_request() {
    local url="$1"
    local response
    local http_code
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [ "$http_code" -ne 200 ]; then
        echo -e "${RED}API request failed with status $http_code for: $url${NC}" >&2
        return 1
    fi
    
    echo "$response"
    return 0
}

# Function to format date for better readability
format_date() {
    local iso_date="$1"
    if command -v date &> /dev/null; then
        # Try to format the date nicely
        if date -d "$iso_date" "+%Y-%m-%d %H:%M" 2>/dev/null; then
            return 0
        else
            # Fallback for systems where -d doesn't work (like macOS)
            echo "$iso_date" | cut -d'T' -f1,2 | tr 'T' ' ' | cut -d':' -f1,2
        fi
    else
        echo "$iso_date"
    fi
}

# Function to get recent commits for a repository
get_recent_commits() {
    local repo="$1"
    local count="${2:-$DEFAULT_COMMIT_COUNT}"
    
    echo -e "${CYAN}📝 Recent commits for ${BOLD}$repo${NC}${CYAN}:${NC}"
    
    local commits_data
    commits_data=$(github_api_request "$GITHUB_API_BASE/repos/$repo/commits?per_page=$count")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  Failed to fetch commits${NC}"
        return 1
    fi
    
    if [ "$commits_data" = "[]" ] || [ -z "$commits_data" ]; then
        echo -e "${YELLOW}  No commits found${NC}"
        return 0
    fi
    
    # Parse and display commits
    echo "$commits_data" | jq -r '.[] | "  \(.sha[0:7]) \(.commit.author.date) \(.commit.author.name): \(.commit.message | split("\n")[0])"' | while read -r commit_line; do
        local sha=$(echo "$commit_line" | awk '{print $1}')
        local date=$(echo "$commit_line" | awk '{print $2}')
        local author_and_message=$(echo "$commit_line" | cut -d' ' -f4-)
        
        local formatted_date=$(format_date "$date")
        echo -e "  ${GREEN}$sha${NC} ${BLUE}$formatted_date${NC} $author_and_message"
    done
    
    echo
}

# Function to get open pull requests for a repository
get_open_prs() {
    local repo="$1"
    
    echo -e "${PURPLE}🔀 Open pull requests for ${BOLD}$repo${NC}${PURPLE}:${NC}"
    
    local prs_data
    prs_data=$(github_api_request "$GITHUB_API_BASE/repos/$repo/pulls?state=open")
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  Failed to fetch pull requests${NC}"
        return 1
    fi
    
    if [ "$prs_data" = "[]" ] || [ -z "$prs_data" ]; then
        echo -e "${YELLOW}  No open pull requests${NC}"
        echo
        return 0
    fi
    
    # Parse and display PRs
    echo "$prs_data" | jq -r '.[] | "#\(.number) \(.created_at) \(.user.login): \(.title)"' | while read -r pr_line; do
        local pr_number=$(echo "$pr_line" | awk '{print $1}')
        local date=$(echo "$pr_line" | awk '{print $2}')
        local author_and_title=$(echo "$pr_line" | cut -d' ' -f4-)
        
        local formatted_date=$(format_date "$date")
        echo -e "  ${YELLOW}$pr_number${NC} ${BLUE}$formatted_date${NC} $author_and_title"
    done
    
    echo
}

# Function to display repository information
show_repo_info() {
    local repo="$1"
    local commit_count="${2:-$DEFAULT_COMMIT_COUNT}"
    
    echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}Repository: $repo${NC}"
    echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo
    
    get_recent_commits "$repo" "$commit_count"
    get_open_prs "$repo"
}

# Function to display help
show_help() {
    echo "GitHub Repository Monitor"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --commits NUM        Number of recent commits to show (default: $DEFAULT_COMMIT_COUNT)"
    echo "  -r, --repo REPO          Monitor specific repository (format: owner/repo)"
    echo "  -o, --org ORG            GitHub organization for dynamic discovery (default: $DEFAULT_GITHUB_ORG)"
    echo "  -p, --prefix PREFIX      Repository name prefix filter (default: $DEFAULT_REPO_PREFIX)"
    echo "  -d, --dynamic            Use dynamic repository discovery instead of configured list"
    echo "  -l, --list               List configured/discovered repositories"
    echo "  -h, --help               Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                          # Monitor configured repositories"
    echo "  $0 -c 10                                   # Show 10 recent commits for each repo"
    echo "  $0 -r NHSDigital/nhs-notify-template       # Monitor only specific repository"
    echo "  $0 -d                                      # Auto-discover repos with default settings"
    echo "  $0 -d -p nhs-notify-web                    # Discover repos with 'nhs-notify-web' prefix"
    echo "  $0 -d -o MyOrg -p api                      # Discover 'api*' repos in 'MyOrg' organization"
    echo "  $0 -d -l                                   # List discovered repositories"
    echo
}

# Function to list configured repositories
list_repositories() {
    echo "Configured repositories:"
    for repo in "${REPOSITORIES[@]}"; do
        echo "  - $repo"
    done
}

# Main function
main() {
    local commit_count=$DEFAULT_COMMIT_COUNT
    local specific_repo=""
    local github_org="$DEFAULT_GITHUB_ORG"
    local repo_prefix="$DEFAULT_REPO_PREFIX"
    local use_dynamic="false"
    local list_only="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--commits)
                commit_count="$2"
                if ! [[ "$commit_count" =~ ^[0-9]+$ ]]; then
                    echo -e "${RED}Error: Commit count must be a number${NC}"
                    exit 1
                fi
                shift 2
                ;;
            -r|--repo)
                specific_repo="$2"
                shift 2
                ;;
            -o|--org)
                github_org="$2"
                shift 2
                ;;
            -p|--prefix)
                repo_prefix="$2"
                shift 2
                ;;
            -d|--dynamic)
                use_dynamic="true"
                shift
                ;;
            -l|--list)
                list_only="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Handle list-only mode
    if [ "$list_only" = "true" ]; then
        initialize_repositories "$use_dynamic" "$github_org" "$repo_prefix"
        list_repositories
        exit 0
    fi
    
    # Initialize repository list (may fetch dynamically)
    initialize_repositories "$use_dynamic" "$github_org" "$repo_prefix"
    
    echo -e "${CYAN}${BOLD}GitHub Repository Monitor${NC}"
    echo -e "${CYAN}Monitoring repositories for recent activity...${NC}"
    echo
    
    # Monitor specific repository or all configured repositories
    if [ -n "$specific_repo" ]; then
        show_repo_info "$specific_repo" "$commit_count"
    else
        if [ ${#REPOSITORIES[@]} -eq 0 ]; then
            echo -e "${YELLOW}No repositories configured. Please edit the script to add repositories.${NC}"
            exit 1
        fi
        
        for repo in "${REPOSITORIES[@]}"; do
            show_repo_info "$repo" "$commit_count"
        done
    fi
    
    echo -e "${GREEN}${BOLD}Monitoring complete!${NC}"
}

# Run the main function with all arguments
main "$@"