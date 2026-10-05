using System.IO.Compression;
using System.Text;
using System.Xml.Linq;
using Intranet.Modulo03.Models;

namespace Intranet.Modulo03.Services;

public class ExcelReportService
{
    public byte[] GenerarInventarioXlsx(IEnumerable<BienInventario> bienes)
    {
        var headers = new[]
        {
            "CBI", "Código inventario", "Descripción", "Clasificación", "Marca",
            "Modelo", "Serie", "Procedencia", "Fecha ingreso", "Estado",
            "Almacén", "Ubicación", "Ambiente", "Responsable", "Observación"
        };

        var rows = new List<string[]> { headers };
        rows.AddRange(bienes.Select(b => new[]
        {
            b.Cbi,
            b.CodigoInventario ?? "",
            b.Descripcion,
            b.Clasificacion,
            b.Marca ?? "",
            b.Modelo ?? "",
            b.Serie ?? "",
            b.Procedencia,
            b.FechaIngreso.ToString("dd/MM/yyyy"),
            b.Estado,
            b.AlmacenActual,
            b.UbicacionAlmacen ?? "",
            b.AmbienteActual ?? "Sin asignar",
            b.Responsable ?? "",
            b.Observacion ?? ""
        }));

        using var stream = new MemoryStream();
        using (var zip = new ZipArchive(stream, ZipArchiveMode.Create, true))
        {
            Write(zip, "[Content_Types].xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
                  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
                </Types>
                """);

            Write(zip, "_rels/.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
                </Relationships>
                """);

            Write(zip, "xl/workbook.xml", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
                  <sheets><sheet name="Inventario" sheetId="1" r:id="rId1"/></sheets>
                </workbook>
                """);

            Write(zip, "xl/_rels/workbook.xml.rels", """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
                </Relationships>
                """);

            var sheet = new XElement(XName.Get("worksheet", "http://schemas.openxmlformats.org/spreadsheetml/2006/main"),
                new XElement(XName.Get("sheetData", "http://schemas.openxmlformats.org/spreadsheetml/2006/main"),
                    rows.Select((row, rowIndex) => new XElement(XName.Get("row", "http://schemas.openxmlformats.org/spreadsheetml/2006/main"),
                        new XAttribute("r", rowIndex + 1),
                        row.Select((value, colIndex) => InlineStringCell(ColumnName(colIndex + 1) + (rowIndex + 1), value))))));

            Write(zip, "xl/worksheets/sheet1.xml", new XDocument(new XDeclaration("1.0", "UTF-8", "yes"), sheet).ToString(SaveOptions.DisableFormatting));
        }

        return stream.ToArray();
    }

    private static XElement InlineStringCell(string reference, string value)
    {
        var ns = XNamespace.Get("http://schemas.openxmlformats.org/spreadsheetml/2006/main");
        return new XElement(ns + "c",
            new XAttribute("r", reference),
            new XAttribute("t", "inlineStr"),
            new XElement(ns + "is", new XElement(ns + "t", value)));
    }

    private static string ColumnName(int index)
    {
        var name = new StringBuilder();
        while (index > 0)
        {
            index--;
            name.Insert(0, (char)('A' + index % 26));
            index /= 26;
        }
        return name.ToString();
    }

    private static void Write(ZipArchive zip, string entryName, string content)
    {
        var entry = zip.CreateEntry(entryName);
        using var writer = new StreamWriter(entry.Open(), new UTF8Encoding(false));
        writer.Write(content.Trim());
    }
}
