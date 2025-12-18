using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

var appConfigEndpoint = builder.Configuration["APP_CONFIG_ENDPOINT"];

if (appConfigEndpoint != null)
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options.Connect(
            new Uri($"https://{appConfigEndpoint}.azconfig.io"),
            new DefaultAzureCredential())
        .Select("*");
    });
}

var app = builder.Build();

app.MapGet("/", () =>
{
    string[] ret = ["HTTP OK", $"App Config: {CheckAppConfig()}"];
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