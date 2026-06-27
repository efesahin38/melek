// DIKKAT: Bu dosya gizlidir. .gitignore'a eklenmeli!
// ACHTUNG: Diese Datei ist geheim. Muss in .gitignore eingetragen werden!

class AppConfig {
  AppConfig._();

  // Neon PostgreSQL Connection String (Neon Console > Dashboard'dan al)
  static const String neonConnectionString = 'postgresql://neondb_owner:npg_cVoNl0B5tvLY@ep-red-water-aiq67fiq-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

  // App version
  static const String appVersion = '1.0.0';
  static const String appName = 'MELEK';
}
