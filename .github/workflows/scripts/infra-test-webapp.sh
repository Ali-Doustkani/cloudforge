# Test if webapp is loading the image from ACR properly

test_webapp(){
    appServiceName=$1
    url="https://${appServiceName}.azurewebsites.net"
    echo "Testing app '$url'"
    timeout=100 #timeout in seconds
    httpcode=$(curl --connect-timeout $timeout -i $url | head -n 1)
    if [[ "$httpcode" == *"200 OK"* ]]; then
    echo "PASSED -- 200OK"
    else 
    echo "Expected 200OK but received $httpcode"
    exit 1
    fi
    welcome=$(curl --connect-timeout $timeout $url | grep "HTTP OK")
    if [[ -z "$welcome" ]]; then
    echo "Expected website content"
    exit 1
    fi
    

    # verify for appconfig access here
}