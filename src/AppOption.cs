using System.ComponentModel.DataAnnotations;

public class AppOption
{
    [Required]
    public required string Secret { get; init; }
}
