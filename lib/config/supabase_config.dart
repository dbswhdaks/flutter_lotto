/// Supabase 프로젝트 설정.
///
/// `anonKey` 는 공개 가능한 키이며, 모든 권한은 데이터베이스 RLS 정책으로 통제된다.
/// 빌드 시 주입하고 싶다면 `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// 형태로 넘기고 `String.fromEnvironment` 로 받아오는 방식으로 교체할 수 있다.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://ymtctbpovnfbkrnmvtii.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InltdGN0YnBvdm5mYmtybm12dGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5MjczNTcsImV4cCI6MjA4MDUwMzM1N30.nFUb5GfUchT470X6IAGCrOFDlUe2Rcz3CIteE8_ar6c';
}
