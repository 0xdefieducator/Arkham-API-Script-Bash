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
