using System.Diagnostics;
using System.Security.Claims;
using System.Text.Json;
using app.Api;
using app.Components;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using app;

var builder = WebApplication.CreateBuilder(args);

if (!string.IsNullOrEmpty(builder.Configuration.GetValue<string>("APPLICATIONINSIGHTS_CONNECTION_STRING")))
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
}

builder.Services.AddSingleton(new ActivitySource("cloudforge.orders"));
builder.Services.AddHttpContextAccessor();
builder.Services.AddRazorPages();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.Use(async (context, next) =>
{
    var header = context.Request.Headers["X-MS-CLIENT-PRINCIPAL"].FirstOrDefault();
    if (header != null)
    {
        var decoded = Convert.FromBase64String(header);
        var json = JsonSerializer.Deserialize<EasyAuthPrincipal>(decoded);
        var claims = json.Claims.Select(x=>new Claim(x.Type, x.Value)).ToList();
        var identity = new ClaimsIdentity(claims, "easyauth");
        context.User = new ClaimsPrincipal(identity);
    }
    await next();
});
app.UseAuthorization();
app.UseAntiforgery();

app.MapRazorPages();

app.MapGet("/health", () => HealthState.IsHealthy
    ? Results.Ok(new { status = "healthy" })
    : Results.Json(new { status = "unhealthy" }, statusCode: 500))
    .DisableAntiforgery();

app.MapOrderEndpoints();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();


app.Run();