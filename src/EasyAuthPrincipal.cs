using System.Text.Json.Serialization;

namespace app;

public record EasyAuthPrincipal([property: JsonPropertyName("claims")] List<EasyAuthClaim> Claims);

public record EasyAuthClaim(
    [property: JsonPropertyName("typ")] string Type,
    [property: JsonPropertyName("val")] string Value);