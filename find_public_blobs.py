# Tool to identify publicly accessible (anonymous access) Azure Blob Storage Containers.

import requests
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed

def check_blob_container(base_url, container_name):
    url = f"{base_url}{container_name}?restype=container&comp=list"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            print(f"[+] Publicly accessible container found: {container_name}")
    except requests.RequestException as e:
        print(f"Error checking {container_name}: {e}")

def brute_force_containers(base_url, wordlist, threads):
    try:
        with open(wordlist, 'r') as f:
            container_names = [line.strip() for line in f]

        with ThreadPoolExecutor(max_workers=threads) as executor:
            futures = {executor.submit(check_blob_container, base_url, container_name) for container_name in container_names}
            for future in as_completed(futures):
                try:
                    future.result()
                except Exception as e:
                    print(f"Error in thread: {e}")

    except KeyboardInterrupt:
        print("\n[!] Script interrupted by user. Exiting...")

def main():
    parser = argparse.ArgumentParser(description="Find publicly accessible Azure Blob containers.")
    parser.add_argument("base_url", help="Base URL of the Azure Blob storage (e.g., https://megabigtechinternal.blob.core.windows.net/)")
    parser.add_argument("-w", "--wordlist", help="Path to a custom wordlist file", required=True)
    parser.add_argument("-t", "--threads", help="Number of threads to use", type=int, default=10)

    args = parser.parse_args()

    base_url = args.base_url.rstrip('/') + '/'
    wordlist = args.wordlist
    threads = args.threads

    brute_force_containers(base_url, wordlist, threads)

if __name__ == "__main__":
    main()

