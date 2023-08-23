#!/bin/bash

# Run subfinder
subfinder -dL domains.txt -o subfinder-subdomains.txt

# Run assetfinder
cat domains.txt | assetfinder --subs-only > assetfinder-subdomains.txt

# Combine subfinder and assetfinder results
cat subfinder-subdomains.txt assetfinder-subdomains.txt > subdomains.txt

# Sort and remove duplicates
sort -u subdomains.txt > sort.txt

# Use httpx to filter out URLs 
cat sort.txt | httpx -title -sc -asn -o httpx.txt -p 8000,8080,8443,443,80,8008,3000,5000,9090,900,7070,9200,15672,9000 -t 75 -location

# Use httpx to filter out URLs with a response code of 200,301,302
cat sort.txt | httpx -mc 200,301,302 > alive_urls.txt

# Use httpx to filter out URLs with a response code of 403
cat sort.txt | httpx -mc 403 > 403.txt

# Use httpx to filter out URLs with a response code of 403
cat sort.txt | httpx -mc 401 > 401.txt

# Use httpx to filter out URLs with a response code of 404
cat sort.txt | httpx -mc 404 > 404.txt

# Iterate over the URLs and run paramspider
while IFS= read -r URL; do
  /home/romiyo/ParamSpider/./paramspider.py -d "${URL}" --level high
done < alive_urls.txt

# check directory using dirhunt tool
#while IFS= read -r DOMAIN; do
 # echo "Scanning domain: $DOMAIN"
 # dirhunt "$DOMAIN"
 # echo "Scan for $DOMAIN completed"
 # echo "-------------------------------------"
#done < alive_urls.txt

output_file="dirhunt_output.log"

while IFS= read -r DOMAIN; do
  echo "Scanning domain: $DOMAIN"
  dirhunt "$DOMAIN" >> "$output_file" 2>&1
  echo "Scan for $DOMAIN completed"
  echo "-------------------------------------"
done < alive_urls.txt

# check subdomain via dns alternative
altdns -i subdomains.txt -o data_output -w /home/romiyo/Desktop/HUNTING/fuzzing/subdomain/words.txt -r -s results_output.txt


# Use katana to filter out URLs with js file
cat alive_urls.txt | katana | grep js | httpx -mc 200 | tee -a js.txt

# Use nuclei to check sensitive information bugs
nuclei -l js.txt -t /home/romiyo/nuclei-templates/exposures -o js_bugs.txt

# Use nuclei to check all bugs
nuclei -l js.txt -t /home/romiyo/nuclei-templates/ -o js_allbugs.txt
