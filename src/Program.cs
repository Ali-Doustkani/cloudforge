using app.Components;
using Azure.Identity;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

var builder = WebApplication.CreateBuilder(args);

// builder.Configuration.AddAzureAppConfiguration(options =>
// {
//     options.Connect(new Uri(builder.Configuration["APP_CONFIG_ENDPOINT"]), new ManagedIdentityCredential())
//         .Select(KeyFilter.Any, labelFilter: builder.Environment.EnvironmentName.ToLower());
// });

builder.Services.AddRazorComponents().AddInteractiveServerComponents();
// builder.Services.Configure<EnvironmentBannerOption>(builder.Configuration.GetSection("UI:EnvironmentBanner"));
var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();


app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
