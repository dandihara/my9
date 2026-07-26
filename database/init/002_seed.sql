INSERT INTO teams (code, name, short_name) VALUES
('LG', 'LG 트윈스', 'LG'),
('OB', '두산 베어스', '두산'),
('SSG', 'SSG 랜더스', 'SSG'),
('WO', '키움 히어로즈', '키움'),
('KT', 'KT 위즈', 'KT'),
('KIA', 'KIA 타이거즈', 'KIA'),
('LT', '롯데 자이언츠', '롯데'),
('SS', '삼성 라이온즈', '삼성'),
('HH', '한화 이글스', '한화'),
('NC', 'NC 다이노스', 'NC')
ON CONFLICT (code) DO UPDATE SET
name = EXCLUDED.name,
short_name = EXCLUDED.short_name,
updated_at = now();

INSERT INTO stadiums (name, city) VALUES
('잠실야구장', '서울'),
('고척스카이돔', '서울'),
('인천SSG랜더스필드', '인천'),
('수원KT위즈파크', '수원'),
('광주기아챔피언스필드', '광주'),
('사직야구장', '부산'),
('대구삼성라이온즈파크', '대구'),
('대전한화생명볼파크', '대전'),
('창원NC파크', '창원')
ON CONFLICT (name) DO NOTHING;
