namespace app.Api;

record Order(int Id, string Item, int Quantity);

static class OrderEndpoints
{
    static readonly List<Order> Orders =
    [
        new(1, "Widget", 10),
        new(2, "Gadget", 5),
    ];

    public static void MapOrderEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/order");

        group.MapGet("/", GetOrders);

        group.MapPost("/", PostOrder);
    }

    private static IResult PostOrder(Order order)
    {
            Orders.Add(order);
            return Results.Created($"/order/{order.Id}", order);
    }

    private static Order[] GetOrders()
    {
        return Orders.ToArray();
    }
}
