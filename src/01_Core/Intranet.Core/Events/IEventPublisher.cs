namespace Intranet.Core.Events;

/// <summary>
/// Publicador desacoplado de eventos en memoria. Permite notificar a otros módulos sin conocerlos.
/// </summary>
public interface IEventPublisher
{
    Task PublishAsync<TEvent>(TEvent evento, CancellationToken cancellationToken = default) where TEvent : IEvent;
}
