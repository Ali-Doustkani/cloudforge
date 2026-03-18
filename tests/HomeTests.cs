using System.Security.Claims;
using Bunit;
using Bunit.TestDoubles;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;
using app.Components.Pages;

namespace app.Tests;

public class HomeTests : BunitContext
{
    private void SetupDependencies(string secret = "test-secret")
    {
        var uiOptions = new Mock<IOptionsSnapshot<UiOption>>();
        uiOptions.Setup(o => o.Value).Returns(new UiOption { AppName = "TestApp" });
        Services.AddSingleton(uiOptions.Object);

        var appOptions = new Mock<IOptionsSnapshot<AppOption>>();
        appOptions.Setup(o => o.Value).Returns(new AppOption { Secret = secret });
        Services.AddSingleton(appOptions.Object);

        var env = new Mock<IWebHostEnvironment>();
        env.Setup(e => e.EnvironmentName).Returns("Testing");
        Services.AddSingleton(env.Object);

        var authState = Task.FromResult(new AuthenticationState(new ClaimsPrincipal()));
        var authProvider = new Mock<AuthenticationStateProvider>();
        authProvider.Setup(p => p.GetAuthenticationStateAsync()).Returns(authState);
        Services.AddSingleton(authProvider.Object);
    }

    [Fact]
    public void Home_DisplaysSecretFromAppConfig()
    {
        SetupDependencies("hello-from-key-vault");

        var cut = Render<Home>();

        Assert.Contains("hello-from-key-vault", cut.Markup);
    }
}
