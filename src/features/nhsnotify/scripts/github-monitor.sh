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
DEFAULT_MAX_PARALLEL=5  # Maximum number of parallel jobs

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

# Function to check GitHub rate limit status
check_rate_limit() {
    local rate_limit_data
    local use_gh_cli=false
    
    # Check if we can use GitHub CLI (authenticated)
    if command -v gh &> /dev/null && gh auth status &>/dev/null; then
        use_gh_cli=true
    fi
    
    if [ "$use_gh_cli" = true ]; then
        rate_limit_data=$(gh api rate_limit 2>/dev/null)
    else
        rate_limit_data=$(curl -s "https://api.github.com/rate_limit")
    fi
    
    if [ $? -eq 0 ] && echo "$rate_limit_data" | jq -e '.rate' >/dev/null 2>&1; then
        local remaining=$(echo "$rate_limit_data" | jq -r '.rate.remaining')
        local limit=$(echo "$rate_limit_data" | jq -r '.rate.limit')
        local reset=$(echo "$rate_limit_data" | jq -r '.rate.reset')
        
        echo -e "${CYAN}GitHub API Rate Limit Status:${NC}"
        if [ "$use_gh_cli" = true ]; then
            echo -e "  Authentication: ${GREEN}GitHub CLI (authenticated)${NC}"
        else
            echo -e "  Authentication: ${YELLOW}Unauthenticated${NC}"
        fi
        echo -e "  Remaining: ${GREEN}$remaining${NC}/$limit requests"
        
        if [ "$remaining" -eq 0 ]; then
            local reset_time=$(date -d "@$reset" 2>/dev/null || date -r "$reset" 2>/dev/null || echo "Unknown")
            echo -e "  ${YELLOW}Rate limit exceeded. Resets at: $reset_time${NC}"
            if [ "$use_gh_cli" = false ]; then
                echo -e "  ${CYAN}Tip: Use GitHub CLI authentication for higher limits (5,000/hour vs 60/hour)${NC}"
                echo -e "  ${CYAN}Run: gh auth login${NC}"
            fi
        fi
        echo
    else
        echo -e "${RED}Failed to check rate limit status${NC}"
        echo
    fi
}

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

# Function to check GitHub CLI authentication status
check_github_cli_auth() {
    if command -v gh &> /dev/null; then
        if gh auth status &>/dev/null; then
            echo "authenticated"
            return 0
        else
            echo "unauthenticated"
            return 1
        fi
    else
        echo "not_installed"
        return 2
    fi
}

# Function to prompt for GitHub authentication with timeout
prompt_github_auth() {
    local auth_status=$(check_github_cli_auth)
    
    # Only prompt if GitHub CLI is available but not authenticated
    if [ "$auth_status" = "unauthenticated" ]; then
        echo -e "${YELLOW}GitHub CLI is installed but not authenticated${NC}"
        echo -e "${CYAN}Authenticating will increase your rate limit from 60 to 5,000 requests/hour${NC}"
        echo
        echo -e "${BOLD}Would you like to authenticate with GitHub? (y/N)${NC}"
        echo -e "${CYAN}(Auto-continuing in 10 seconds if no response...)${NC}"
        
        # Read with timeout
        local response
        if read -t 10 -r response; then
            echo  # Add newline after user input
            case "${response,,}" in  # Convert to lowercase
                y|yes)
                    echo -e "${CYAN}Starting GitHub authentication...${NC}"
                    if gh auth login --insecure-storage; then
                        echo -e "${GREEN}✓ Authentication successful!${NC}"
                        echo
                        return 0
                    else
                        echo -e "${YELLOW}Authentication failed or cancelled. Continuing unauthenticated.${NC}"
                        echo
                        return 1
                    fi
                    ;;
                *)
                    echo -e "${CYAN}Continuing unauthenticated as requested.${NC}"
                    echo
                    return 1
                    ;;
            esac
        else
            echo  # Add newline after timeout
            echo -e "${CYAN}No response received. Continuing unauthenticated.${NC}"
            echo
            return 1
        fi
    elif [ "$auth_status" = "not_installed" ]; then
        echo -e "${YELLOW}GitHub CLI is not installed${NC}"
        echo -e "${CYAN}Installing GitHub CLI would allow authentication for higher rate limits (5,000 vs 60 requests/hour)${NC}"
        echo -e "${CYAN}Visit: https://cli.github.com/ for installation instructions${NC}"
        echo
        return 1
    fi
    
    # Already authenticated or other status
    return 0
}

# Function to get authentication status and rate limits
get_auth_status() {
    local auth_status=$(check_github_cli_auth)
    
    case $auth_status in
        "authenticated")
            local username=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
            echo -e "${GREEN}✓ GitHub CLI authenticated as: $username${NC}"
            echo -e "${GREEN}  Rate limit: 5,000 requests/hour${NC}"
            ;;
        "unauthenticated")
            echo -e "${YELLOW}⚠ GitHub CLI installed but not authenticated${NC}"
            echo -e "${YELLOW}  Rate limit: 60 requests/hour${NC}"
            echo -e "${CYAN}  Tip: Run 'gh auth login' for higher rate limits${NC}"
            ;;
        "not_installed")
            echo -e "${YELLOW}⚠ GitHub CLI not installed${NC}"
            echo -e "${YELLOW}  Rate limit: 60 requests/hour${NC}"
            echo -e "${CYAN}  Tip: Install GitHub CLI and run 'gh auth login' for higher rate limits${NC}"
            ;;
    esac
    echo
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
    local use_gh_cli=false
    
    # Check if we can use GitHub CLI (authenticated)
    if command -v gh &> /dev/null && gh auth status &>/dev/null; then
        use_gh_cli=true
    fi
    
    if [ "$use_gh_cli" = true ]; then
        # Use GitHub CLI for authenticated requests
        local endpoint
        endpoint=$(echo "$url" | sed 's|https://api.github.com/||')
        
        response=$(gh api "$endpoint" 2>&1)
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "$response"
            return 0
        else
            # Parse GitHub CLI error for better error messages
            if echo "$response" | grep -q "rate limit exceeded"; then
                echo -e "${YELLOW}Rate limit exceeded. Even with authentication!${NC}" >&2
            elif echo "$response" | grep -q "Not Found"; then
                echo -e "${RED}Repository not found or not accessible${NC}" >&2
            else
                echo -e "${RED}GitHub CLI request failed for: $endpoint${NC}" >&2
                echo -e "${RED}Error: $response${NC}" >&2
            fi
            return 1
        fi
    else
        # Fall back to curl for unauthenticated requests
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
        http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        response=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
        
        if [ "$http_code" -ne 200 ]; then
            # Check if it's a rate limiting error (GitHub uses 403 for rate limits)
            if [ "$http_code" -eq 403 ] && echo "$response" | grep -q "rate limit exceeded"; then
                echo -e "${YELLOW}Rate limit exceeded. Consider using GitHub authentication for higher limits.${NC}" >&2
                echo -e "${CYAN}Run 'gh auth login' to authenticate and get 5,000 requests/hour${NC}" >&2
            elif [ "$http_code" -eq 404 ]; then
                echo -e "${RED}Repository not found or not accessible${NC}" >&2
            else
                echo -e "${RED}API request failed with status $http_code for: $url${NC}" >&2
                if [ -n "$response" ] && echo "$response" | jq -e '.message' >/dev/null 2>&1; then
                    local error_message=$(echo "$response" | jq -r '.message')
                    echo -e "${RED}Error: $error_message${NC}" >&2
                fi
            fi
            return 1
        fi
        
        echo "$response"
        return 0
    fi
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

# Function to process a single repository and save output to file
process_repository() {
    local repo="$1"
    local commit_count="$2"
    local output_file="$3"
    
    {
        echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}${BOLD}Repository: $repo${NC}"
        echo -e "${WHITE}${BOLD}═══════════════════════════════════════════════════════════════════════════════${NC}"
        echo
        
        get_recent_commits "$repo" "$commit_count"
        get_open_prs "$repo"
    } > "$output_file" 2>&1
}

# Function to manage parallel repository processing
process_repositories_parallel() {
    local commit_count="$1"
    local max_parallel="${2:-$DEFAULT_MAX_PARALLEL}"
    local temp_dir
    temp_dir=$(mktemp -d)
    local pids=()
    local repo_count=0
    local start_time=$(date +%s)
    
    echo -e "${CYAN}Processing ${#REPOSITORIES[@]} repositories with up to $max_parallel parallel jobs...${NC}"
    echo
    
    # Process repositories in batches
    for repo in "${REPOSITORIES[@]}"; do
        local output_file="$temp_dir/repo_${repo_count}.out"
        
        # Start background job
        process_repository "$repo" "$commit_count" "$output_file" &
        local pid=$!
        pids+=($pid)
        
        ((repo_count++))
        
        # If we've reached max parallel jobs, wait for some to complete
        if [ ${#pids[@]} -ge $max_parallel ]; then
            # Wait for the first job to complete
            wait ${pids[0]}
            pids=("${pids[@]:1}")  # Remove first PID from array
        fi
    done
    
    # Wait for all remaining jobs to complete
    echo -e "${CYAN}Waiting for remaining jobs to complete...${NC}"
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo -e "${GREEN}All repository processing jobs completed in ${duration}s. Displaying results...${NC}"
    echo
    
    # Display results in order
    for ((i=0; i<repo_count; i++)); do
        local output_file="$temp_dir/repo_${i}.out"
        if [ -f "$output_file" ]; then
            cat "$output_file"
        fi
    done
    
    # Clean up temporary files
    rm -rf "$temp_dir"
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
    echo "  -j, --parallel NUM       Maximum parallel jobs (default: $DEFAULT_MAX_PARALLEL, 1 for sequential)"
    echo "  -l, --list               List configured/discovered repositories"
    echo "  --rate-limit             Check GitHub API rate limit status"
    echo "  --no-auth-prompt         Skip GitHub authentication prompt"
    echo "  -h, --help               Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                          # Monitor configured repositories"
    echo "  $0 -c 10                                   # Show 10 recent commits for each repo"
    echo "  $0 -r NHSDigital/nhs-notify-template       # Monitor only specific repository"
    echo "  $0 -d                                      # Auto-discover repos with default settings"
    echo "  $0 -d -p nhs-notify-web                    # Discover repos with 'nhs-notify-web' prefix"
    echo "  $0 -d -o MyOrg -p api                      # Discover 'api*' repos in 'MyOrg' organization"
    echo "  $0 -d -j 10                                # Use 10 parallel jobs for faster processing"
    echo "  $0 -j 1                                    # Process repositories sequentially"
    echo "  $0 --no-auth-prompt                       # Skip authentication prompt"
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
    local max_parallel=$DEFAULT_MAX_PARALLEL
    local skip_auth_prompt="false"
    
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
            -j|--parallel)
                max_parallel="$2"
                if ! [[ "$max_parallel" =~ ^[0-9]+$ ]] || [ "$max_parallel" -lt 1 ]; then
                    echo -e "${RED}Error: Parallel job count must be a positive number${NC}"
                    exit 1
                fi
                shift 2
                ;;
            -l|--list)
                list_only="true"
                shift
                ;;
            --rate-limit)
                check_rate_limit
                exit 0
                ;;
            --no-auth-prompt)
                skip_auth_prompt="true"
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
    
    # Prompt for authentication (unless skipped or in list-only mode)
    if [ "$skip_auth_prompt" = "false" ] && [ "$list_only" = "false" ]; then
        prompt_github_auth
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
    
    # Show authentication status
    get_auth_status
    
    # Check rate limit status before starting
    check_rate_limit
    
    # Monitor specific repository or all configured repositories
    if [ -n "$specific_repo" ]; then
        show_repo_info "$specific_repo" "$commit_count"
    else
        if [ ${#REPOSITORIES[@]} -eq 0 ]; then
            echo -e "${YELLOW}No repositories configured. Please edit the script to add repositories.${NC}"
            exit 1
        fi
        
        # Use parallel processing if more than one repository and max_parallel > 1
        if [ ${#REPOSITORIES[@]} -gt 1 ] && [ "$max_parallel" -gt 1 ]; then
            echo -e "${CYAN}Using parallel processing with up to $max_parallel concurrent jobs${NC}"
            process_repositories_parallel "$commit_count" "$max_parallel"
        else
            if [ "$max_parallel" -eq 1 ]; then
                echo -e "${CYAN}Processing repositories sequentially${NC}"
            fi
            for repo in "${REPOSITORIES[@]}"; do
                show_repo_info "$repo" "$commit_count"
            done
        fi
    fi
    
    echo -e "${GREEN}${BOLD}Monitoring complete!${NC}"
}

# Run the main function with all arguments
main "$@"