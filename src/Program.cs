using app;
using app.Components;
using Azure.Identity;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;
using Microsoft.FeatureManagement;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddAzureAppConfiguration(options =>
{
    var credential = new DefaultAzureCredential();
    options.Connect(new Uri(builder.Configuration["APP_CONFIG_ENDPOINT"] ?? throw new InvalidOperationException("this env var is required")), credential)
        .Select(KeyFilter.Any, labelFilter: "EN")
        .Select(KeyFilter.Any, labelFilter: LabelFilter.Null)
        .UseFeatureFlags(x => x.SetRefreshInterval(TimeSpan.FromSeconds(10)))
        .ConfigureRefresh(r => r.Register("App:ConfigVersion", refreshAll: true)
                                .SetRefreshInterval(TimeSpan.FromSeconds(10)))
        .ConfigureKeyVault(kv => kv.SetCredential(credential));
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddAzureAppConfiguration();
builder.Services.AddFeatureManagement().WithTargeting<TargetingContextAccessor>();
builder.Services.AddScoped<IIncrementProvider, VariantIncrementProvider>();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie();
builder.Services.AddRazorPages();
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.Configure<AppOption>(builder.Configuration.GetSection("App"));
builder.Services.AddOptionsWithValidateOnStart<AppOption>().ValidateDataAnnotations();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseAzureAppConfiguration();
app.UseAuthentication();
app.UseAntiforgery();

app.MapRazorPages();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
