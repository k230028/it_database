-- 메뉴 시드 (멱등: MERGE INTO ... WHEN NOT MATCHED). 수동 실행.
-- 한글 문자열이 포함되므로 NLS_LANG=.AL32UTF8 환경에서 실행해야 ORA-01756을 피한다.
--   NLS_LANG=.AL32UTF8 sqlplus -S ITPAPP/****@127.0.0.1:1521/XEPDB1 @V20260603_008__SeedRouteCatalogAndMenuTree.sql
-- SoT: it_frontend/app/components/AppSidebar.vue 의 menuItems / context / adminLogMenuGroups
-- SRE_TC: 01=info 02=audit 03=admin 04=board 05=documents 06=approval
-- 블록 순서 중요: 라우트(1) → 메뉴(2) → 권한(3). LNK 노드의 SRE_PTH는 반드시 라우트에 선존재해야 FK 충족.

SET DEFINE OFF;
SET SQLBLANKLINES ON;

-- =====================================================================
-- 1) 라우트 카탈로그 (AppSidebar.vue의 모든 to 경로). 리프 라벨을 SRE_MNU_NM으로 사용.
-- =====================================================================
MERGE INTO TPRMPP_CMENUD t
USING (
  -- info (01)
  SELECT '/info'                  AS SRE_PTH, 'Home'                  AS SRE_MNU_NM, '01' AS SRE_TC FROM DUAL UNION ALL
  SELECT '/guide',                  '사업 가이드',            '01' FROM DUAL UNION ALL
  SELECT '/budget',                 '예산 작성',              '01' FROM DUAL UNION ALL
  SELECT '/budget/approval',        '결재 상신',              '01' FROM DUAL UNION ALL
  SELECT '/budget/list',            '예산 목록',              '01' FROM DUAL UNION ALL
  SELECT '/budget/work',            '예산 작업',              '01' FROM DUAL UNION ALL
  SELECT '/budget/status',          '예산 현황',              '01' FROM DUAL UNION ALL
  SELECT '/budget/summary',         '예산 조회',              '01' FROM DUAL UNION ALL
  SELECT '/budget/comparison',      '예산 비교',              '01' FROM DUAL UNION ALL
  SELECT '/info/plan/form',         '계획 작성',              '01' FROM DUAL UNION ALL
  SELECT '/info/plan',              '계획 목록',              '01' FROM DUAL UNION ALL
  SELECT '/info/projects',          '사업 목록',              '01' FROM DUAL UNION ALL
  SELECT '/info/council-request',   '정보화실무협의회 신청',  '01' FROM DUAL UNION ALL
  SELECT '/info/estimation',        '소요예산 산정 신청',     '01' FROM DUAL UNION ALL
  SELECT '/info/deliberation',      '과업심의위원회 신청',    '01' FROM DUAL UNION ALL
  SELECT '/info/contract',          '입찰/계약 의뢰',         '01' FROM DUAL UNION ALL
  SELECT '/info/payment',           '대금지급 의뢰',          '01' FROM DUAL UNION ALL
  SELECT '/info/evaluation',        '성과평가',               '01' FROM DUAL UNION ALL
  -- audit (02)
  SELECT '/audit',                  '홈',                     '02' FROM DUAL UNION ALL
  SELECT '/audit/daily',            '일일감사',               '02' FROM DUAL UNION ALL
  SELECT '/audit/monthly',          '월별감사',               '02' FROM DUAL UNION ALL
  SELECT '/audit/quarterly',        '분기감사',               '02' FROM DUAL UNION ALL
  SELECT '/audit/biannual',         '반기감사',               '02' FROM DUAL UNION ALL
  SELECT '/audit/annual',           '연간감사',               '02' FROM DUAL UNION ALL
  SELECT '/audit/manage/daily',     '일일감사 운영',          '02' FROM DUAL UNION ALL
  SELECT '/audit/manage/monthly',   '월별감사 운영',          '02' FROM DUAL UNION ALL
  SELECT '/audit/manage/quarterly', '분기감사 운영',          '02' FROM DUAL UNION ALL
  SELECT '/audit/manage/biannual',  '반기감사 운영',          '02' FROM DUAL UNION ALL
  SELECT '/audit/manage/annual',    '연간감사 운영',          '02' FROM DUAL UNION ALL
  -- admin (03)
  SELECT '/admin/dashboard',        '대시보드',               '03' FROM DUAL UNION ALL
  SELECT '/admin/codes',            '공통코드',               '03' FROM DUAL UNION ALL
  SELECT '/admin/auth-grades',      '자격등급',               '03' FROM DUAL UNION ALL
  SELECT '/admin/users',            '사용자',                 '03' FROM DUAL UNION ALL
  SELECT '/admin/roles',            '역할',                   '03' FROM DUAL UNION ALL
  SELECT '/admin/organizations',    '조직',                   '03' FROM DUAL UNION ALL
  SELECT '/admin/boards',           '게시판 관리',            '03' FROM DUAL UNION ALL
  SELECT '/admin/login-history',    '로그인 이력',            '03' FROM DUAL UNION ALL
  SELECT '/admin/tokens',           'JWT 갱신토큰',           '03' FROM DUAL UNION ALL
  SELECT '/admin/files',            '첨부파일',               '03' FROM DUAL UNION ALL
  SELECT '/admin/realtime-logs',    '실시간 로그',            '03' FROM DUAL UNION ALL
  SELECT '/admin/menus',            '메뉴관리',               '03' FROM DUAL UNION ALL
  SELECT '/admin/routes',           '라우트관리',             '03' FROM DUAL UNION ALL
  -- admin 상세 로그 리프 (/admin/logs/{key})
  SELECT '/admin/logs/bbugt',       '예산 작업·편성 결과',    '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/bplanm',      '계획 조회·등록',         '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/bprojm',      '사업 목록·상세',         '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/bitemm',      '사업 예산 비목',         '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/bcostm',      '전산업무비',             '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/btermm',      '단말기 상세목록',        '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/brdocm',      '사전협의 문서',          '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/brivgm',      '검토의견',               '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/bgdocm',      '사업 가이드',            '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/capplm',      '전자결재 신청서',        '03' FROM DUAL UNION ALL
  SELECT '/admin/logs/ccodem',      '공통코드 관리',          '03' FROM DUAL UNION ALL
  -- documents (05)
  SELECT '/info/documents',                        'Home',       '05' FROM DUAL UNION ALL
  SELECT '/info/documents/list',                   '요청 목록',  '05' FROM DUAL UNION ALL
  SELECT '/info/documents/form',                   '신규 작성',  '05' FROM DUAL UNION ALL
  SELECT '/info/documents/list?status=reviewing',  '검토 중',    '05' FROM DUAL UNION ALL
  SELECT '/info/documents/list?status=completed',  '협의 완료',  '05' FROM DUAL UNION ALL
  SELECT '/info/documents/list?status=overdue',    '지연',       '05' FROM DUAL UNION ALL
  -- approval (06)
  SELECT '/approval',                            'Home',           '06' FROM DUAL UNION ALL
  SELECT '/approval/list?tab=pending',           '결재 대기',     '06' FROM DUAL UNION ALL
  SELECT '/approval/list?tab=done',              '결재 완료',     '06' FROM DUAL UNION ALL
  SELECT '/approval/list?tab=in-progress',       '결재 진행 중',  '06' FROM DUAL UNION ALL
  SELECT '/approval/list?tab=draft-done',        '완료 기안',     '06' FROM DUAL UNION ALL
  SELECT '/approval/list?tab=draft-rejected',    '반려 기안',     '06' FROM DUAL
) s ON (t.SRE_PTH = s.SRE_PTH)
WHEN NOT MATCHED THEN
  INSERT (SRE_PTH, SRE_MNU_NM, SRE_TC, USE_YN, DEL_YN, GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.SRE_PTH, s.SRE_MNU_NM, s.SRE_TC, 'Y', 'N', RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

-- =====================================================================
-- 2) 메뉴 트리 (WHL_MNU_PTH·MNU_DEP 명시 계산). GRP/DYN은 SRE_PTH=NULL, LNK는 필수.
-- =====================================================================
MERGE INTO TPRMPP_CMENUM t
USING (
  -- ===== info (01) =====
  SELECT 'MINF0001' AS MNU_ID, CAST(NULL AS VARCHAR2(10)) AS HRK_MNU_ID, '01' AS SRE_TC,
         'Home' AS MNU_NM, 'LNK' AS MNU_TP_C, CAST('/info' AS VARCHAR2(300)) AS SRE_PTH,
         10 AS MNU_SOT_SQN_SNO, 'N' AS HID_YN, 1 AS MNU_DEP, '/MINF0001' AS WHL_MNU_PTH FROM DUAL UNION ALL
  SELECT 'MINF0002', NULL, '01', '사업 가이드', 'LNK', '/guide',
         20, 'N', 1, '/MINF0002' FROM DUAL UNION ALL
  -- 전산예산 GRP
  SELECT 'MINF0003', NULL, '01', '전산예산', 'GRP', NULL,
         30, 'N', 1, '/MINF0003' FROM DUAL UNION ALL
  SELECT 'MINF0004', 'MINF0003', '01', '예산 작성', 'LNK', '/budget',
         10, 'N', 2, '/MINF0003/MINF0004' FROM DUAL UNION ALL
  SELECT 'MINF0005', 'MINF0003', '01', '결재 상신', 'LNK', '/budget/approval',
         20, 'N', 2, '/MINF0003/MINF0005' FROM DUAL UNION ALL
  SELECT 'MINF0006', 'MINF0003', '01', '예산 목록', 'LNK', '/budget/list',
         30, 'N', 2, '/MINF0003/MINF0006' FROM DUAL UNION ALL
  SELECT 'MINF0007', 'MINF0003', '01', '예산 작업', 'LNK', '/budget/work',
         40, 'N', 2, '/MINF0003/MINF0007' FROM DUAL UNION ALL
  SELECT 'MINF0008', 'MINF0003', '01', '예산 현황', 'LNK', '/budget/status',
         50, 'N', 2, '/MINF0003/MINF0008' FROM DUAL UNION ALL
  -- 정보기술부문 예산 GRP (admin)
  SELECT 'MINF0009', NULL, '01', '정보기술부문 예산', 'GRP', NULL,
         40, 'N', 1, '/MINF0009' FROM DUAL UNION ALL
  SELECT 'MINF0010', 'MINF0009', '01', '예산 조회', 'LNK', '/budget/summary',
         10, 'N', 2, '/MINF0009/MINF0010' FROM DUAL UNION ALL
  SELECT 'MINF0011', 'MINF0009', '01', '예산 비교', 'LNK', '/budget/comparison',
         20, 'N', 2, '/MINF0009/MINF0011' FROM DUAL UNION ALL
  -- 정보기술부문 계획 GRP (admin)
  SELECT 'MINF0012', NULL, '01', '정보기술부문 계획', 'GRP', NULL,
         50, 'N', 1, '/MINF0012' FROM DUAL UNION ALL
  SELECT 'MINF0013', 'MINF0012', '01', '계획 작성', 'LNK', '/info/plan/form',
         10, 'N', 2, '/MINF0012/MINF0013' FROM DUAL UNION ALL
  SELECT 'MINF0014', 'MINF0012', '01', '계획 목록', 'LNK', '/info/plan',
         20, 'N', 2, '/MINF0012/MINF0014' FROM DUAL UNION ALL
  -- 정보화사업 GRP
  SELECT 'MINF0015', NULL, '01', '정보화사업', 'GRP', NULL,
         60, 'N', 1, '/MINF0015' FROM DUAL UNION ALL
  SELECT 'MINF0016', 'MINF0015', '01', '사업 목록', 'LNK', '/info/projects',
         10, 'N', 2, '/MINF0015/MINF0016' FROM DUAL UNION ALL
  SELECT 'MINF0017', 'MINF0015', '01', '정보화실무협의회 신청', 'LNK', '/info/council-request',
         20, 'N', 2, '/MINF0015/MINF0017' FROM DUAL UNION ALL
  SELECT 'MINF0018', 'MINF0015', '01', '소요예산 산정 신청', 'LNK', '/info/estimation',
         30, 'N', 2, '/MINF0015/MINF0018' FROM DUAL UNION ALL
  SELECT 'MINF0019', 'MINF0015', '01', '과업심의위원회 신청', 'LNK', '/info/deliberation',
         40, 'N', 2, '/MINF0015/MINF0019' FROM DUAL UNION ALL
  SELECT 'MINF0020', 'MINF0015', '01', '입찰/계약 의뢰', 'LNK', '/info/contract',
         50, 'N', 2, '/MINF0015/MINF0020' FROM DUAL UNION ALL
  SELECT 'MINF0021', 'MINF0015', '01', '대금지급 의뢰', 'LNK', '/info/payment',
         60, 'N', 2, '/MINF0015/MINF0021' FROM DUAL UNION ALL
  SELECT 'MINF0022', 'MINF0015', '01', '성과평가', 'LNK', '/info/evaluation',
         70, 'N', 2, '/MINF0015/MINF0022' FROM DUAL UNION ALL

  -- ===== audit (02) =====
  SELECT 'MAUD0001', NULL, '02', '홈', 'LNK', '/audit',
         10, 'N', 1, '/MAUD0001' FROM DUAL UNION ALL
  SELECT 'MAUD0002', NULL, '02', 'IT자체감사', 'GRP', NULL,
         20, 'N', 1, '/MAUD0002' FROM DUAL UNION ALL
  SELECT 'MAUD0003', 'MAUD0002', '02', '일일감사', 'LNK', '/audit/daily',
         10, 'N', 2, '/MAUD0002/MAUD0003' FROM DUAL UNION ALL
  SELECT 'MAUD0004', 'MAUD0002', '02', '월별감사', 'LNK', '/audit/monthly',
         20, 'N', 2, '/MAUD0002/MAUD0004' FROM DUAL UNION ALL
  SELECT 'MAUD0005', 'MAUD0002', '02', '분기감사', 'LNK', '/audit/quarterly',
         30, 'N', 2, '/MAUD0002/MAUD0005' FROM DUAL UNION ALL
  SELECT 'MAUD0006', 'MAUD0002', '02', '반기감사', 'LNK', '/audit/biannual',
         40, 'N', 2, '/MAUD0002/MAUD0006' FROM DUAL UNION ALL
  SELECT 'MAUD0007', 'MAUD0002', '02', '연간감사', 'LNK', '/audit/annual',
         50, 'N', 2, '/MAUD0002/MAUD0007' FROM DUAL UNION ALL
  SELECT 'MAUD0008', NULL, '02', 'IT자체감사 운영', 'GRP', NULL,
         30, 'N', 1, '/MAUD0008' FROM DUAL UNION ALL
  SELECT 'MAUD0009', 'MAUD0008', '02', '일일감사 운영', 'LNK', '/audit/manage/daily',
         10, 'N', 2, '/MAUD0008/MAUD0009' FROM DUAL UNION ALL
  SELECT 'MAUD0010', 'MAUD0008', '02', '월별감사 운영', 'LNK', '/audit/manage/monthly',
         20, 'N', 2, '/MAUD0008/MAUD0010' FROM DUAL UNION ALL
  SELECT 'MAUD0011', 'MAUD0008', '02', '분기감사 운영', 'LNK', '/audit/manage/quarterly',
         30, 'N', 2, '/MAUD0008/MAUD0011' FROM DUAL UNION ALL
  SELECT 'MAUD0012', 'MAUD0008', '02', '반기감사 운영', 'LNK', '/audit/manage/biannual',
         40, 'N', 2, '/MAUD0008/MAUD0012' FROM DUAL UNION ALL
  SELECT 'MAUD0013', 'MAUD0008', '02', '연간감사 운영', 'LNK', '/audit/manage/annual',
         50, 'N', 2, '/MAUD0008/MAUD0013' FROM DUAL UNION ALL

  -- ===== admin (03) — 컨텍스트 전체 admin 전용 =====
  SELECT 'MADM0001', NULL, '03', '메뉴관리', 'LNK', '/admin/menus',
         10, 'N', 1, '/MADM0001' FROM DUAL UNION ALL
  SELECT 'MADM0002', NULL, '03', '라우트관리', 'LNK', '/admin/routes',
         20, 'N', 1, '/MADM0002' FROM DUAL UNION ALL
  SELECT 'MADM0003', NULL, '03', '대시보드', 'LNK', '/admin/dashboard',
         30, 'N', 1, '/MADM0003' FROM DUAL UNION ALL
  -- 데이터 관리 GRP
  SELECT 'MADM0004', NULL, '03', '데이터 관리', 'GRP', NULL,
         40, 'N', 1, '/MADM0004' FROM DUAL UNION ALL
  SELECT 'MADM0005', 'MADM0004', '03', '공통코드', 'LNK', '/admin/codes',
         10, 'N', 2, '/MADM0004/MADM0005' FROM DUAL UNION ALL
  SELECT 'MADM0006', 'MADM0004', '03', '자격등급', 'LNK', '/admin/auth-grades',
         20, 'N', 2, '/MADM0004/MADM0006' FROM DUAL UNION ALL
  SELECT 'MADM0007', 'MADM0004', '03', '사용자', 'LNK', '/admin/users',
         30, 'N', 2, '/MADM0004/MADM0007' FROM DUAL UNION ALL
  SELECT 'MADM0008', 'MADM0004', '03', '역할', 'LNK', '/admin/roles',
         40, 'N', 2, '/MADM0004/MADM0008' FROM DUAL UNION ALL
  SELECT 'MADM0009', 'MADM0004', '03', '조직', 'LNK', '/admin/organizations',
         50, 'N', 2, '/MADM0004/MADM0009' FROM DUAL UNION ALL
  -- 콘텐츠 관리 GRP
  SELECT 'MADM0010', NULL, '03', '콘텐츠 관리', 'GRP', NULL,
         50, 'N', 1, '/MADM0010' FROM DUAL UNION ALL
  SELECT 'MADM0011', 'MADM0010', '03', '게시판 관리', 'LNK', '/admin/boards',
         10, 'N', 2, '/MADM0010/MADM0011' FROM DUAL UNION ALL
  -- 이력·보안 GRP
  SELECT 'MADM0012', NULL, '03', '이력 · 보안', 'GRP', NULL,
         60, 'N', 1, '/MADM0012' FROM DUAL UNION ALL
  SELECT 'MADM0013', 'MADM0012', '03', '로그인 이력', 'LNK', '/admin/login-history',
         10, 'N', 2, '/MADM0012/MADM0013' FROM DUAL UNION ALL
  SELECT 'MADM0014', 'MADM0012', '03', 'JWT 갱신토큰', 'LNK', '/admin/tokens',
         20, 'N', 2, '/MADM0012/MADM0014' FROM DUAL UNION ALL
  SELECT 'MADM0015', 'MADM0012', '03', '첨부파일', 'LNK', '/admin/files',
         30, 'N', 2, '/MADM0012/MADM0015' FROM DUAL UNION ALL
  -- 실시간 로그 (LNK, admin:true)
  SELECT 'MADM0016', NULL, '03', '실시간 로그', 'LNK', '/admin/realtime-logs',
         70, 'N', 1, '/MADM0016' FROM DUAL UNION ALL
  -- 상세 로그 GRP → 6개 서브그룹(depth2) → 로그 링크(depth3)
  SELECT 'MADM0017', NULL, '03', '상세 로그', 'GRP', NULL,
         80, 'N', 1, '/MADM0017' FROM DUAL UNION ALL
  -- 서브그룹 1: 전산예산
  SELECT 'MADM0018', 'MADM0017', '03', '전산예산', 'GRP', NULL,
         10, 'N', 2, '/MADM0017/MADM0018' FROM DUAL UNION ALL
  SELECT 'MADM0019', 'MADM0018', '03', '예산 작업·편성 결과', 'LNK', '/admin/logs/bbugt',
         10, 'N', 3, '/MADM0017/MADM0018/MADM0019' FROM DUAL UNION ALL
  -- 서브그룹 2: 정보기술부문 계획
  SELECT 'MADM0020', 'MADM0017', '03', '정보기술부문 계획', 'GRP', NULL,
         20, 'N', 2, '/MADM0017/MADM0020' FROM DUAL UNION ALL
  SELECT 'MADM0021', 'MADM0020', '03', '계획 조회·등록', 'LNK', '/admin/logs/bplanm',
         10, 'N', 3, '/MADM0017/MADM0020/MADM0021' FROM DUAL UNION ALL
  -- 서브그룹 3: 정보화사업
  SELECT 'MADM0022', 'MADM0017', '03', '정보화사업', 'GRP', NULL,
         30, 'N', 2, '/MADM0017/MADM0022' FROM DUAL UNION ALL
  SELECT 'MADM0023', 'MADM0022', '03', '사업 목록·상세', 'LNK', '/admin/logs/bprojm',
         10, 'N', 3, '/MADM0017/MADM0022/MADM0023' FROM DUAL UNION ALL
  SELECT 'MADM0024', 'MADM0022', '03', '사업 예산 비목', 'LNK', '/admin/logs/bitemm',
         20, 'N', 3, '/MADM0017/MADM0022/MADM0024' FROM DUAL UNION ALL
  -- 서브그룹 4: 전산업무비
  SELECT 'MADM0025', 'MADM0017', '03', '전산업무비', 'GRP', NULL,
         40, 'N', 2, '/MADM0017/MADM0025' FROM DUAL UNION ALL
  SELECT 'MADM0026', 'MADM0025', '03', '전산업무비', 'LNK', '/admin/logs/bcostm',
         10, 'N', 3, '/MADM0017/MADM0025/MADM0026' FROM DUAL UNION ALL
  SELECT 'MADM0027', 'MADM0025', '03', '단말기 상세목록', 'LNK', '/admin/logs/btermm',
         20, 'N', 3, '/MADM0017/MADM0025/MADM0027' FROM DUAL UNION ALL
  -- 서브그룹 5: 사전협의
  SELECT 'MADM0028', 'MADM0017', '03', '사전협의', 'GRP', NULL,
         50, 'N', 2, '/MADM0017/MADM0028' FROM DUAL UNION ALL
  SELECT 'MADM0029', 'MADM0028', '03', '사전협의 문서', 'LNK', '/admin/logs/brdocm',
         10, 'N', 3, '/MADM0017/MADM0028/MADM0029' FROM DUAL UNION ALL
  SELECT 'MADM0030', 'MADM0028', '03', '검토의견', 'LNK', '/admin/logs/brivgm',
         20, 'N', 3, '/MADM0017/MADM0028/MADM0030' FROM DUAL UNION ALL
  SELECT 'MADM0031', 'MADM0028', '03', '사업 가이드', 'LNK', '/admin/logs/bgdocm',
         30, 'N', 3, '/MADM0017/MADM0028/MADM0031' FROM DUAL UNION ALL
  -- 서브그룹 6: 전자결재·공통관리
  SELECT 'MADM0032', 'MADM0017', '03', '전자결재·공통관리', 'GRP', NULL,
         60, 'N', 2, '/MADM0017/MADM0032' FROM DUAL UNION ALL
  SELECT 'MADM0033', 'MADM0032', '03', '전자결재 신청서', 'LNK', '/admin/logs/capplm',
         10, 'N', 3, '/MADM0017/MADM0032/MADM0033' FROM DUAL UNION ALL
  SELECT 'MADM0034', 'MADM0032', '03', '공통코드 관리', 'LNK', '/admin/logs/ccodem',
         20, 'N', 3, '/MADM0017/MADM0032/MADM0034' FROM DUAL UNION ALL

  -- ===== board (04) — 동적 게시판 목록 노드 =====
  SELECT 'MBRD0001', NULL, '04', '게시판', 'DYN', NULL,
         10, 'N', 1, '/MBRD0001' FROM DUAL UNION ALL

  -- ===== documents (05) =====
  SELECT 'MDOC0001', NULL, '05', 'Home', 'LNK', '/info/documents',
         10, 'N', 1, '/MDOC0001' FROM DUAL UNION ALL
  SELECT 'MDOC0002', NULL, '05', '사전협의', 'GRP', NULL,
         20, 'N', 1, '/MDOC0002' FROM DUAL UNION ALL
  SELECT 'MDOC0003', 'MDOC0002', '05', '요청 목록', 'LNK', '/info/documents/list',
         10, 'N', 2, '/MDOC0002/MDOC0003' FROM DUAL UNION ALL
  SELECT 'MDOC0004', 'MDOC0002', '05', '신규 작성', 'LNK', '/info/documents/form',
         20, 'N', 2, '/MDOC0002/MDOC0004' FROM DUAL UNION ALL
  SELECT 'MDOC0005', NULL, '05', '상태별 현황', 'GRP', NULL,
         30, 'N', 1, '/MDOC0005' FROM DUAL UNION ALL
  SELECT 'MDOC0006', 'MDOC0005', '05', '검토 중', 'LNK', '/info/documents/list?status=reviewing',
         10, 'N', 2, '/MDOC0005/MDOC0006' FROM DUAL UNION ALL
  SELECT 'MDOC0007', 'MDOC0005', '05', '협의 완료', 'LNK', '/info/documents/list?status=completed',
         20, 'N', 2, '/MDOC0005/MDOC0007' FROM DUAL UNION ALL
  SELECT 'MDOC0008', 'MDOC0005', '05', '지연', 'LNK', '/info/documents/list?status=overdue',
         30, 'N', 2, '/MDOC0005/MDOC0008' FROM DUAL UNION ALL

  -- ===== approval (06) =====
  SELECT 'MAPV0001', NULL, '06', 'Home', 'LNK', '/approval',
         10, 'N', 1, '/MAPV0001' FROM DUAL UNION ALL
  SELECT 'MAPV0002', NULL, '06', '결재함', 'GRP', NULL,
         20, 'N', 1, '/MAPV0002' FROM DUAL UNION ALL
  SELECT 'MAPV0003', 'MAPV0002', '06', '결재 대기', 'LNK', '/approval/list?tab=pending',
         10, 'N', 2, '/MAPV0002/MAPV0003' FROM DUAL UNION ALL
  SELECT 'MAPV0004', 'MAPV0002', '06', '결재 완료', 'LNK', '/approval/list?tab=done',
         20, 'N', 2, '/MAPV0002/MAPV0004' FROM DUAL UNION ALL
  SELECT 'MAPV0005', NULL, '06', '기안함', 'GRP', NULL,
         30, 'N', 1, '/MAPV0005' FROM DUAL UNION ALL
  SELECT 'MAPV0006', 'MAPV0005', '06', '결재 진행 중', 'LNK', '/approval/list?tab=in-progress',
         10, 'N', 2, '/MAPV0005/MAPV0006' FROM DUAL UNION ALL
  SELECT 'MAPV0007', 'MAPV0005', '06', '완료 기안', 'LNK', '/approval/list?tab=draft-done',
         20, 'N', 2, '/MAPV0005/MAPV0007' FROM DUAL UNION ALL
  SELECT 'MAPV0008', 'MAPV0005', '06', '반려 기안', 'LNK', '/approval/list?tab=draft-rejected',
         30, 'N', 2, '/MAPV0005/MAPV0008' FROM DUAL
) s ON (t.MNU_ID = s.MNU_ID)
WHEN NOT MATCHED THEN
  INSERT (MNU_ID, HRK_MNU_ID, SRE_TC, MNU_NM, MNU_TP_C, SRE_PTH, MNU_SOT_SQN_SNO, HID_YN, MNU_DEP, WHL_MNU_PTH,
          DEL_YN, GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.MNU_ID, s.HRK_MNU_ID, s.SRE_TC, s.MNU_NM, s.MNU_TP_C, s.SRE_PTH, s.MNU_SOT_SQN_SNO, s.HID_YN, s.MNU_DEP, s.WHL_MNU_PTH,
          'N', RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

-- =====================================================================
-- 3) 권한 매핑 (admin:true 노드 → ITPAD001). 그 외 노드는 매핑 없음 = 전체 공개.
--    admin 컨텍스트(SRE_TC='03') 전체 + info의 admin:true GRP/리프.
-- =====================================================================
MERGE INTO TPRMPP_CMENUA t
USING (
  -- info context의 admin:true 노드 (예산 작업/현황, 정보기술부문 예산·계획 그룹 및 그 리프)
  SELECT 'MINF0007' AS MNU_ID, 'ITPAD001' AS ATH_ID FROM DUAL UNION ALL  -- 예산 작업
  SELECT 'MINF0008', 'ITPAD001' FROM DUAL UNION ALL                       -- 예산 현황
  SELECT 'MINF0009', 'ITPAD001' FROM DUAL UNION ALL                       -- 정보기술부문 예산 GRP
  SELECT 'MINF0010', 'ITPAD001' FROM DUAL UNION ALL                       -- 예산 조회
  SELECT 'MINF0011', 'ITPAD001' FROM DUAL UNION ALL                       -- 예산 비교
  SELECT 'MINF0012', 'ITPAD001' FROM DUAL UNION ALL                       -- 정보기술부문 계획 GRP
  SELECT 'MINF0013', 'ITPAD001' FROM DUAL UNION ALL                       -- 계획 작성
  SELECT 'MINF0014', 'ITPAD001' FROM DUAL UNION ALL                       -- 계획 목록
  -- admin context (SRE_TC='03') 전체 노드 (메뉴관리/라우트관리 포함)
  SELECT 'MADM0001', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0002', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0003', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0004', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0005', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0006', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0007', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0008', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0009', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0010', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0011', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0012', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0013', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0014', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0015', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0016', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0017', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0018', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0019', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0020', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0021', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0022', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0023', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0024', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0025', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0026', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0027', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0028', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0029', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0030', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0031', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0032', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0033', 'ITPAD001' FROM DUAL UNION ALL
  SELECT 'MADM0034', 'ITPAD001' FROM DUAL
) s ON (t.MNU_ID = s.MNU_ID AND t.ATH_ID = s.ATH_ID)
WHEN NOT MATCHED THEN
  INSERT (MNU_ID, ATH_ID, DEL_YN, GUID, GUID_PRG_SNO, FST_ENR_DTM, FST_ENR_USID)
  VALUES (s.MNU_ID, s.ATH_ID, 'N', RAWTOHEX(SYS_GUID()), 1, SYSDATE, 'SYSTEM');

COMMIT;
