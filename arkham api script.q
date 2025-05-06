// ####################################################################################################
// ARKHAM SCRIPT
// ####################################################################################################

// ------------------ OVERVIEW ------------------
// This script will pull data from the arkham API using the GET transfers endpoint, see docs here (https://arkham-intelligence.notion.site/Arkham-API-Access-9232652274854efaa8a67633a94a2595).
// The script needs to have the parameters adjusted manually for now, in the future maybe the ideal way would be to pass in arguments more easily somehow. 
// This will spit out a json file with the results, a log file to keep tabs on what happened, and then convert the json file into a csv to for faster and easier uploading. 
// qstudio has the 'load CSV data' function in the tools section in the GUI which speeds up and makes importing of tables faster, more efficient and easier (to noobs like me). 
// ----------------------------------------------


// 1.	API Fetch Script: Dedicated to fetching data from different API endpoints and saving it as JSON & converting it (ARKHAM & DEFINED)
// the below script is saved as an .sh bash file in home directory. 

#!/opt/homebrew/bin/bash
set -euo pipefail

# Global Configuration
API_URL="https://api.arkhamintelligence.com/transfers"
API_KEY="xxx" 
JSON_FILE="response_dynamic.json"
OUTPUT_CSV="transfers_dynamic.csv"
LOG_FILE="./api_fetch.log"

# Function: Log messages with timestamps
log_message() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$level" "$*" | tee -a "$LOG_FILE"
}

# Function: Build the query string
build_query_string() {
    local -A params  # Declare as local associative array
    
    # Initialize all parameters
    params=(
        ["base"]="type:cex"  		  # REQUIRED, (e.g. "gate-io,bybit,mexc" OR "type:cex")
        ["chains"]=""		          # Supported chains (empty for all)
        ["flow"]=""                       # Flow /w respect to base - "out" you'll only see transactions coming from base regardless of other filter
        ["from"]=""                       # Filter for transactions from certain entities
        ["to"]="deposit:all"		  # Example: Adjusted: transfers to Gate.io and Bybit
        ["tokens"]="connext"              # Adjusted: Specific token (coingecko ID or contract address)
        ["timeGte"]=""                    # Transactions after a certain time
        ["timeLte"]=""                    # Transactions before a certain time
        ["timeLast"]=""                   # Duration for transfers
        ["valueGte"]=""                   # Minimum token value
        ["valueLte"]=""                   # Maximum token value
        ["usdGte"]="2000"                 # Minimum USD value
        ["usdLte"]=""                     # Maximum USD value
        ["sortKey"]="time"                # Sort key 	 "time" | "value" | "usd"
        ["sortDir"]="desc"                # Sort direction	"asc" | "desc"
        ["limit"]=""                      # Number of transfers to return, default is "20"
        ["offset"]=""                     # Pagination offset
    )

    local query_string=""
    for key in "${!params[@]}"; do
        [[ -n "${params[$key]}" ]] && query_string+="${key}=${params[$key]}&"
    done

    echo "${query_string%&}"
}

# Function: Fetch data from the API
fetch_data() {
    local query_string; query_string=$(build_query_string)

    if [[ -z "$query_string" ]]; then
        log_message "ERROR" "No query parameters provided. Exiting."
        return 1
    fi

    local full_url="${API_URL}?${query_string}"
    log_message "INFO" "Fetching data from: $full_url"

    local response; response=$(curl -s -w "%{http_code}" -o "$JSON_FILE" -X GET "$full_url" -H "API-Key: $API_KEY")
    local http_code="${response: -3}"

    if [[ "$http_code" -ne 200 ]]; then
        log_message "ERROR" "API call failed with status code $http_code"
        return 1
    fi

    log_message "INFO" "Data successfully fetched. Response saved to $JSON_FILE."
    return 0
}

# Function: Generate CSV dynamically from JSON
generate_csv_dynamic() {
    log_message "INFO" "Processing JSON and dynamically generating CSV."

    # Extract headers dynamically
    local headers="transactionHash,fromAddress.address,fromAddress.chain,fromAddress.arkhamEntity.name,fromAddress.arkhamEntity.type,fromAddress.arkhamLabel.name,fromIsContract,toAddress.address,toAddress.chain,toAddress.arkhamLabel.name,toIsContract,tokenAddress,blockTimestamp,blockNumber,blockHash,tokenName,tokenSymbol,unitValue,historicalUSD"

    # Generate CSV dynamically
    (
        echo "$headers"
        jq -r '
          .transfers[] |
          {
            "transactionHash": .transactionHash,
            "fromAddress.address": .fromAddress.address,
            "fromAddress.chain": .fromAddress.chain,
            "fromAddress.arkhamEntity.name": (.fromAddress.arkhamEntity.name // "null"),
            "fromAddress.arkhamEntity.type": (.fromAddress.arkhamEntity.type // "null"),
            "fromAddress.arkhamLabel.name": (.fromAddress.arkhamLabel.name // "null"),
            "fromIsContract": .fromIsContract,
            "toAddress.address": .toAddress.address,
            "toAddress.chain": .toAddress.chain,
            "toAddress.arkhamLabel.name": (.toAddress.arkhamLabel.name // "null"),
            "toIsContract": .toIsContract,
            "tokenAddress": .tokenAddress,
            "blockTimestamp": .blockTimestamp,
            "blockNumber": .blockNumber,
            "blockHash": .blockHash,
            "tokenName": .tokenName,
            "tokenSymbol": .tokenSymbol,
            "unitValue": .unitValue,
            "historicalUSD": .historicalUSD
          } | [.[]] | @csv
        ' "$JSON_FILE"
    ) > "$OUTPUT_CSV"

    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to generate CSV from JSON. Exiting."
        return 1
    fi

    log_message "INFO" "Dynamic CSV file generated: $OUTPUT_CSV"
}


# Main function
main() {
    log_message "INFO" "Starting the API fetch and dynamic data processing."

    # Fetch data from the API
    if ! fetch_data; then
        log_message "ERROR" "Failed to fetch data from the API."
        exit 1
    fi

    # Generate CSV from the fetched JSON data
    if ! generate_csv_dynamic; then
        log_message "ERROR" "Failed to generate CSV from JSON."
        exit 1
    fi

    log_message "INFO" "Process completed successfully."
}

main "$@"
// end of bash file script
