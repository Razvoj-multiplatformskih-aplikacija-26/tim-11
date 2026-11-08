import 'package:relic/relic.dart';

Middleware corsZaBackoffice(String dozvoljeniOrigin) =>
    (Handler sledeci) => (Request zahtev) async {
      final origin = zahtev.headers.origin?.toString();
      if (origin == null) return await sledeci(zahtev);
      if (origin != dozvoljeniOrigin) return Response.forbidden();

      if (zahtev.method == Method.options) {
        return Response.noContent(
          headers: Headers.build(
            (headers) => _dodajCorsZaglavlja(headers, origin),
          ),
        );
      }

      final rezultat = await sledeci(zahtev);
      if (rezultat is! Response) return rezultat;

      return rezultat.copyWith(
        headers: rezultat.headers.transform(
          (headers) => _dodajCorsZaglavlja(headers, origin),
        ),
      );
    };

void _dodajCorsZaglavlja(MutableHeaders headers, String origin) {
  headers['Access-Control-Allow-Origin'] = [origin];
  headers['Access-Control-Allow-Methods'] = ['GET, POST, OPTIONS'];
  headers['Access-Control-Allow-Headers'] = ['Content-Type, Authorization'];
  headers['Vary'] = ['Origin'];
}
