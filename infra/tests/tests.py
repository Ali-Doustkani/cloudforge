import sys
import requests

assert len(sys.argv) == 2, "Expected to get webapp name URL as input"

appServiceName = sys.argv[1]
url = f"https://{appServiceName}.azurewebsites.net"

response = requests.get(url)
assert response.status_code == 200, f"Expected HTTP Status Code 200 but received {response.status_code}"

assert "HTTP OK" in response.text, f"Expected response to contain 'HTTP OK' but was '{response.text}'"
