using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.FeatureManagement.FeatureFilters;

namespace app;

public class TargetingContextAccessor(IHttpContextAccessor httpContextAccessor) : ITargetingContextAccessor
{
    public ValueTask<TargetingContext> GetContextAsync()
    {
        var user = httpContextAccessor.HttpContext?.User;
        var userId = user?.FindFirstValue(ClaimTypes.Name);
        var groups = user?.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList() ?? [];

        return new ValueTask<TargetingContext>(new TargetingContext
        {
            UserId = userId,
            Groups = groups
        });
    }
}
