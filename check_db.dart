import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(
      host: 'db.liaxlvzamusqoaayjexi.supabase.co',
      database: 'postgres',
      username: 'postgres',
      password: '[E1F2E338efe38!]',
      port: 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  final result = await connection.execute('SELECT * FROM public.users;');
  print('Users found: ${result.length}');
  for (final row in result) {
    print(row.toColumnMap());
  }
  
  await connection.close();
}
