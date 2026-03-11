using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.FeatureManagement.FeatureFilters;
using Moq;
using Xunit;

namespace app.Tests;

public class TargetingContextAccessorTests
{
    [Fact]
    public async Task GetContextAsync_AuthenticatedUser_ReturnsUserIdAndGroups()
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "user@example.com"),
            new Claim(ClaimTypes.Role, "beta"),
            new Claim(ClaimTypes.Role, "employees"),
        };
        var identity = new ClaimsIdentity(claims, "Test");
        var httpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) };
        var httpContextAccessor = new Mock<IHttpContextAccessor>();
        httpContextAccessor.Setup(x => x.HttpContext).Returns(httpContext);

        var accessor = new TargetingContextAccessor(httpContextAccessor.Object);
        var context = await accessor.GetContextAsync();

        Assert.Equal("user@example.com", context.UserId);
        Assert.Equal(["beta", "employees"], context.Groups);
    }

    [Fact]
    public async Task GetContextAsync_UnauthenticatedUser_ReturnsEmptyContext()
    {
        var httpContext = new DefaultHttpContext();
        var httpContextAccessor = new Mock<IHttpContextAccessor>();
        httpContextAccessor.Setup(x => x.HttpContext).Returns(httpContext);

        var accessor = new TargetingContextAccessor(httpContextAccessor.Object);
        var context = await accessor.GetContextAsync();

        Assert.Null(context.UserId);
        Assert.Empty(context.Groups);
    }
}
