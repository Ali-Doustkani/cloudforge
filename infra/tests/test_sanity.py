import pytest
import requests

# assert len(sys.argv) == 2, "Expected to get webapp name URL as input"

# url = sys.argv[1]
# print(f"Testing '{url}'")

def test_http_ok(url):
    response = requests.get(url)
    assert response.status_code == 200, f"Expected HTTP Status Code 200 but received {response.status_code}"

@pytest.fixture
def url(pytestconfig):
    return pytestconfig.getoption("url")

# assert "HTTP OK" in response.text, f"Expected response to contain 'HTTP OK' but was '{response.text}'"

# assert "App Config: infra_value" in response.text, f"Expected response to contain 'App Config: infra_value' but was '{response.text}'"

# assert "Key Vault: infra_value" in response.text, f"Expected response to contain 'Key Vault: infra_value' but was '{response.text}'"

# assert "Set Secret: denied" in response.text, f"Expected response to contain 'Set Secret: denied' but was '{response.text}'"    