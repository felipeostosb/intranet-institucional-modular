namespace Intranet.Core.Events;

/// <summary>
/// Manejador de eventos que cualquier módulo puede implementar para reaccionar a sucesos de otros módulos.
/// </summary>
public interface IEventHandler<in TEvent> where TEvent : IEvent
{
    Task HandleAsync(TEvent evento, CancellationToken cancellationToken = default);
}
