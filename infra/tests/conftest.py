def pytest_addoption(parser):
    parser.addoption("--url", action="store", required=True, help="URL of the web app")