using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var builder = WebApplication.CreateBuilder(args);

var appConfigEndpoint = builder.Configuration["APP_CONFIG_ENDPOINT"];
var keyVaultEndpoint = builder.Configuration["KV_ENDPOINT"];

if (!string.IsNullOrEmpty(appConfigEndpoint))
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options.Connect(
            new Uri(appConfigEndpoint),
            new DefaultAzureCredential())
        .Select("*");
    });
}

var app = builder.Build();

app.MapGet("/", () =>
{
    string[] ret = [
        "HTTP OK",
         $"App Config: {CheckAppConfig()}",
         $"Key Vault: {CheckKeyVault()}",
         ];
    return string.Join(Environment.NewLine, ret);
});

app.Run();


string CheckAppConfig()
{
    if (string.IsNullOrEmpty(appConfigEndpoint))
    {
        return "Endpoint not set. Expects APP_CONFIG_ENDPOINT";
    }
    try
    {
        return app.Configuration["infra_default"] ?? "NO VALUE";
    }
    catch (Exception ex)
    {
        return ex.Message;
    }
}

string CheckKeyVault()
{
    if (string.IsNullOrEmpty(keyVaultEndpoint))
    {
        return "Endpoint not set. Expectes KV_ENDPOINT";
    }
    try
    {
        var uri = new Uri(keyVaultEndpoint);
        var client = new SecretClient(uri, new DefaultAzureCredential());
        return client.GetSecret("infra-default").Value.Value;
    }
    catch (Exception ex)
    {
        return ex.Message;
    }
}