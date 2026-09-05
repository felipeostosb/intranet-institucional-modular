using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Intranet.Core.Events;

public class InMemoryEventBus : IEventPublisher
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<InMemoryEventBus> _logger;

    public InMemoryEventBus(IServiceProvider serviceProvider, ILogger<InMemoryEventBus> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    public async Task PublishAsync<TEvent>(TEvent evento, CancellationToken cancellationToken = default) where TEvent : IEvent
    {
        using var scope = _serviceProvider.CreateScope();
        var handlers = scope.ServiceProvider.GetServices<IEventHandler<TEvent>>();

        foreach (var handler in handlers)
        {
            try
            {
                await handler.HandleAsync(evento, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[EventBus] Error al procesar evento {EventType} en {HandlerType}", typeof(TEvent).Name, handler.GetType().Name);
            }
        }
    }
}
