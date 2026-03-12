using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.AspNetCore.Mvc.ViewFeatures;
using Moq;
using Xunit;
using app.Pages;

namespace app.Tests;

public class LoginModelTests
{
    private static PageContext CreatePageContext(HttpContext httpContext)
    {
        var actionDescriptor = new PageActionDescriptor
        {
            AttributeRouteInfo = new Microsoft.AspNetCore.Routing.RouteValueDictionary().Count >= 0
                ? new Microsoft.AspNetCore.Mvc.Routing.AttributeRouteInfo { Template = "/Login" }
                : null
        };
        return new PageContext(new Microsoft.AspNetCore.Mvc.ActionContext(
            httpContext,
            new RouteData(),
            actionDescriptor))
        {
            ViewData = new ViewDataDictionary(new EmptyModelMetadataProvider(), new ModelStateDictionary())
        };
    }

    [Fact]
    public async Task OnPostAsync_WithNameAndRoles_SignsInWithCorrectClaims()
    {
        ClaimsPrincipal? capturedPrincipal = null;
        var authService = new Mock<IAuthenticationService>();
        authService
            .Setup(x => x.SignInAsync(It.IsAny<HttpContext>(), It.IsAny<string>(), It.IsAny<ClaimsPrincipal>(), It.IsAny<AuthenticationProperties>()))
            .Callback<HttpContext, string, ClaimsPrincipal, AuthenticationProperties>((_, _, p, _) => capturedPrincipal = p)
            .Returns(Task.CompletedTask);

        var services = new Mock<IServiceProvider>();
        services.Setup(x => x.GetService(typeof(IAuthenticationService))).Returns(authService.Object);
        var httpContext = new DefaultHttpContext { RequestServices = services.Object };

        var model = new LoginModel { PageContext = CreatePageContext(httpContext) };
        var result = await model.OnPostAsync("alice", "employees, beta");

        Assert.IsType<RedirectResult>(result);
        Assert.NotNull(capturedPrincipal);
        Assert.Equal("alice", capturedPrincipal.FindFirstValue(ClaimTypes.Name));
        Assert.Contains(capturedPrincipal.FindAll(ClaimTypes.Role), c => c.Value == "employees");
        Assert.Contains(capturedPrincipal.FindAll(ClaimTypes.Role), c => c.Value == "beta");
    }

    [Fact]
    public async Task OnPostAsync_WithNoRoles_SignsInWithOnlyNameClaim()
    {
        ClaimsPrincipal? capturedPrincipal = null;
        var authService = new Mock<IAuthenticationService>();
        authService
            .Setup(x => x.SignInAsync(It.IsAny<HttpContext>(), It.IsAny<string>(), It.IsAny<ClaimsPrincipal>(), It.IsAny<AuthenticationProperties>()))
            .Callback<HttpContext, string, ClaimsPrincipal, AuthenticationProperties>((_, _, p, _) => capturedPrincipal = p)
            .Returns(Task.CompletedTask);

        var services = new Mock<IServiceProvider>();
        services.Setup(x => x.GetService(typeof(IAuthenticationService))).Returns(authService.Object);
        var httpContext = new DefaultHttpContext { RequestServices = services.Object };

        var model = new LoginModel { PageContext = CreatePageContext(httpContext) };
        await model.OnPostAsync("alice", "");

        Assert.NotNull(capturedPrincipal);
        Assert.Equal("alice", capturedPrincipal.FindFirstValue(ClaimTypes.Name));
        Assert.Empty(capturedPrincipal.FindAll(ClaimTypes.Role));
    }
}
