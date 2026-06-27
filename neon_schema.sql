-- ========================================================
-- MELEK App - Neon PostgreSQL Şema
-- Neon Console > SQL Editor'a yapıştırın ve çalıştırın
-- ========================================================

-- UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── KULLANICILAR ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL CHECK (role IN ('admin', 'employee')),
  phone         TEXT,
  fcm_token     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role  ON users(role);

-- ─── BELGE KLASÖRLER (sabit 11 adet) ─────────────────────────────
CREATE TABLE IF NOT EXISTS document_folders (
  id   SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

INSERT INTO document_folders (id, name) VALUES
  (1,  'Arbeitsvertrag'),
  (2,  'Personaldokumente'),
  (3,  'Gehaltsabrechnung'),
  (4,  'Krankenversicherung'),
  (5,  'Steuerunterlagen'),
  (6,  'Bescheinigungen'),
  (7,  'Führerschein / Qualifikation'),
  (8,  'Arbeitszeit & Urlaub'),
  (9,  'Abmahnungen / Disziplin'),
  (10, 'Sonstige Dokumente'),
  (11, 'Arbeitszeitnachweis')
ON CONFLICT (id) DO NOTHING;

-- ─── ÇALIŞAN BELGELERİ ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS employee_documents (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  folder_id   INT  NOT NULL REFERENCES document_folders(id),
  file_name   TEXT NOT NULL,
  file_data   TEXT,          -- base64 encoded
  file_url    TEXT,
  file_type   TEXT DEFAULT 'application/octet-stream',
  uploaded_by UUID REFERENCES users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_docs_employee ON employee_documents(employee_id);
CREATE INDEX IF NOT EXISTS idx_docs_folder   ON employee_documents(folder_id);

-- ─── TURLAR (İŞLER) ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tours (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tour_date     DATE NOT NULL,
  location_name TEXT NOT NULL,
  address       TEXT NOT NULL,
  description   TEXT,
  driver_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  driver_name   TEXT,
  status        TEXT DEFAULT 'pending'
                     CHECK (status IN ('pending','accepted','in_progress','completed')),
  accepted_at   TIMESTAMPTZ,
  completed_at  TIMESTAMPTZ,
  created_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tours_date      ON tours(tour_date);
CREATE INDEX IF NOT EXISTS idx_tours_driver    ON tours(driver_id);
CREATE INDEX IF NOT EXISTS idx_tours_status    ON tours(status);

-- Trigger: sürücü adını otomatik doldur
CREATE OR REPLACE FUNCTION sync_driver_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.driver_id IS NOT NULL THEN
    SELECT name INTO NEW.driver_name FROM users WHERE id = NEW.driver_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_driver_name
BEFORE INSERT OR UPDATE ON tours
FOR EACH ROW EXECUTE FUNCTION sync_driver_name();

-- ─── STUNDENZETTELs ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS stundenzettels (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  employee_name       TEXT,
  month               INT  NOT NULL CHECK (month BETWEEN 1 AND 12),
  year                INT  NOT NULL,
  total_days          INT  DEFAULT 0,
  total_hours         NUMERIC(6,2) DEFAULT 0,
  work_entries        JSONB DEFAULT '[]',
  admin_signature     TEXT,          -- base64 PNG
  employee_signature  TEXT,          -- base64 PNG
  admin_signed_at     TIMESTAMPTZ,
  employee_signed_at  TIMESTAMPTZ,
  status              TEXT DEFAULT 'draft'
                           CHECK (status IN ('draft','admin_signed','completed')),
  created_by          UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, month, year)
);

CREATE INDEX IF NOT EXISTS idx_sz_employee ON stundenzettels(employee_id);
CREATE INDEX IF NOT EXISTS idx_sz_status   ON stundenzettels(status);

-- Trigger: çalışan adını otomatik doldur
CREATE OR REPLACE FUNCTION sync_employee_name_sz()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.employee_id IS NOT NULL THEN
    SELECT name INTO NEW.employee_name FROM users WHERE id = NEW.employee_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_employee_name_sz
BEFORE INSERT OR UPDATE ON stundenzettels
FOR EACH ROW EXECUTE FUNCTION sync_employee_name_sz();

-- ─── BİLDİRİMLER (ileride kullanmak için) ────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  is_read    BOOLEAN DEFAULT FALSE,
  tour_id    UUID REFERENCES tours(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_user ON notifications(user_id);

-- ─── İLK ADMIN HESABI ───────────────────────────────────────────
-- Varsayılan şifre: Admin1234
-- SHA-256 hash: 968ff3b79ee5dbb22cf0fdbab8e7e9fb2de24a0b7a25dae0e5c9aed5b9a3ca1
-- Giriş yaptıktan sonra şifreyi değiştirin!
INSERT INTO users (name, email, password_hash, role) VALUES
  ('Administrator',
   'admin@melek.de',
   '968ff3b79ee5dbb22cf0fdbab8e7e9fb2de24a0b7a25dae0e5c9aed5b9a3ca1',
   'admin')
ON CONFLICT (email) DO NOTHING;

-- ─── KONTROL SORGUSU ────────────────────────────────────────────
SELECT 'Tabellen erstellt:' AS info;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
