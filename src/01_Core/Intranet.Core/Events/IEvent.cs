namespace Intranet.Core.Events;

/// <summary>
/// Marcador base para cualquier evento de dominio o comunicación entre módulos.
/// </summary>
public interface IEvent
{
    DateTime OcurridoEn => DateTime.UtcNow;
}
