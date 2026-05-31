// deno-lint-ignore-file no-explicit-any
//
// 동행복권 판매점 크롤러
//
// 1. 17개 시/도 × 시/군/구 전체에 대해 https://www.dhlottery.co.kr/prchsplcsrch/selectLtShp.do
//    엔드포인트를 동시성 12로 호출 (페이지당 30개, 최대 페이지수 자동 검출).
// 2. 응답을 normalize 해서 public.lotto_stores 테이블에 store_no 키로 UPSERT.
//
// 트리거:
//   - pg_cron 에서 주 1회 net.http_post() 로 호출 (X-Cron-Token 헤더 필수)
//   - 수동 실행 시: curl -X POST <url> -H "X-Cron-Token: <CRAWL_TOKEN>"
//
// 응답: { inserted_or_updated: number, sidos: number, sigungus: number, took_ms: number }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 공유 시크릿. 함수 자체와 pg_cron 호출이 같은 값을 사용한다.
// 외부 노출 시 누구나 크롤 트리거 가능하므로 절대 코드 외부로 유출 금지.
const CRAWL_TOKEN = "lotto_crawl_5fK3pQ8wB2nV7xR9";

// ============================================================================
// 시/도 → 동행복권 API 단축 이름 + 시/군/구 매핑
// ============================================================================

const CTPV_MAP: Record<string, string> = {
  "서울특별시": "서울",
  "부산광역시": "부산",
  "대구광역시": "대구",
  "인천광역시": "인천",
  "광주광역시": "광주",
  "대전광역시": "대전",
  "울산광역시": "울산",
  "세종특별자치시": "세종",
  "경기도": "경기",
  "강원특별자치도": "강원",
  "충청북도": "충북",
  "충청남도": "충남",
  "전북특별자치도": "전북",
  "전라남도": "전남",
  "경상북도": "경북",
  "경상남도": "경남",
  "제주특별자치도": "제주",
};

const SIGUNGU_MAP: Record<string, string[]> = {
  "서울특별시": [
    "강남구", "강동구", "강북구", "강서구", "관악구", "광진구",
    "구로구", "금천구", "노원구", "도봉구", "동대문구", "동작구",
    "마포구", "서대문구", "서초구", "성동구", "성북구", "송파구",
    "양천구", "영등포구", "용산구", "은평구", "종로구", "중구", "중랑구",
  ],
  "부산광역시": [
    "강서구", "금정구", "남구", "동구", "동래구", "부산진구",
    "북구", "사상구", "사하구", "서구", "수영구", "연제구",
    "영도구", "중구", "해운대구", "기장군",
  ],
  "대구광역시": [
    "남구", "달서구", "동구", "북구", "서구", "수성구", "중구", "달성군",
  ],
  "인천광역시": [
    "계양구", "남동구", "동구", "미추홀구", "부평구", "서구", "연수구",
    "중구", "강화군", "옹진군",
  ],
  "광주광역시": ["광산구", "남구", "동구", "북구", "서구"],
  "대전광역시": ["대덕구", "동구", "서구", "유성구", "중구"],
  "울산광역시": ["남구", "동구", "북구", "중구", "울주군"],
  "세종특별자치시": ["세종특별자치시"],
  "경기도": [
    "수원시", "성남시", "의정부시", "안양시", "부천시", "광명시",
    "평택시", "동두천시", "안산시", "고양시", "과천시", "구리시",
    "남양주시", "오산시", "시흥시", "군포시", "의왕시", "하남시",
    "용인시", "파주시", "이천시", "안성시", "김포시", "화성시",
    "광주시", "양주시", "포천시", "여주시", "연천군", "가평군", "양평군",
  ],
  "강원특별자치도": [
    "춘천시", "원주시", "강릉시", "동해시", "태백시", "속초시", "삼척시",
    "홍천군", "횡성군", "영월군", "평창군", "정선군", "철원군",
    "화천군", "양구군", "인제군", "고성군", "양양군",
  ],
  "충청북도": [
    "청주시", "충주시", "제천시",
    "보은군", "옥천군", "영동군", "증평군", "진천군",
    "괴산군", "음성군", "단양군",
  ],
  "충청남도": [
    "천안시", "공주시", "보령시", "아산시", "서산시", "논산시", "계룡시", "당진시",
    "금산군", "부여군", "서천군", "청양군", "홍성군", "예산군", "태안군",
  ],
  "전북특별자치도": [
    "전주시", "군산시", "익산시", "정읍시", "남원시", "김제시",
    "완주군", "진안군", "무주군", "장수군", "임실군", "순창군", "고창군", "부안군",
  ],
  "전라남도": [
    "목포시", "여수시", "순천시", "나주시", "광양시",
    "담양군", "곡성군", "구례군", "고흥군", "보성군", "화순군",
    "장흥군", "강진군", "해남군", "영암군", "무안군", "함평군",
    "영광군", "장성군", "완도군", "진도군", "신안군",
  ],
  "경상북도": [
    "포항시", "경주시", "김천시", "안동시", "구미시", "영주시", "영천시",
    "상주시", "문경시", "경산시",
    "군위군", "의성군", "청송군", "영양군", "영덕군", "청도군", "고령군",
    "성주군", "칠곡군", "예천군", "봉화군", "울진군", "울릉군",
  ],
  "경상남도": [
    "창원시", "진주시", "통영시", "사천시", "김해시", "밀양시", "거제시", "양산시",
    "의령군", "함안군", "창녕군", "고성군", "남해군", "하동군",
    "산청군", "함양군", "거창군", "합천군",
  ],
  "제주특별자치도": ["제주시", "서귀포시"],
};

// ============================================================================
// 동행복권 API 호출
// ============================================================================

const ENDPOINT =
  "https://www.dhlottery.co.kr/prchsplcsrch/selectLtShp.do";

interface RawStore {
  ltShpId?: string;
  conmNm?: string;
  bplcRdnmDaddr?: string;
  bplcLctnDaddr?: string;
  tm1BplcLctnAddr?: string;
  tm2BplcLctnAddr?: string;
  tm3BplcLctnAddr?: string;
  shpTelno?: string;
  shpLat?: string | number;
  shpLot?: string | number;
  l645LtNtslYn?: string;
  pt720NtslYn?: string;
}

async function fetchPage(params: {
  sidoShort: string;
  sigungu: string;
  page: number;
  only645: boolean;
}): Promise<RawStore[]> {
  const q = new URLSearchParams({
    l645LtNtslYn: params.only645 ? "Y" : "N",
    l520LtNtslYn: "N",
    st5LtNtslYn: "N",
    st10LtNtslYn: "N",
    st20LtNtslYn: "N",
    cpexUsePsbltyYn: "N",
    srchCtpvNm: params.sidoShort,
    srchSggNm: params.sigungu,
    pageNum: String(params.page),
    recordCountPerPage: "30",
    pageCount: "5",
  });

  const res = await fetch(`${ENDPOINT}?${q.toString()}`, {
    headers: {
      "Accept": "application/json",
      "AJAX": "true",
      "X-Requested-With": "XMLHttpRequest",
      "requestMenuUri": "/prchsplcsrch/home",
      "Referer": "https://www.dhlottery.co.kr/prchsplcsrch/home",
      "User-Agent":
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Mobile Safari/537.36",
    },
  });

  if (!res.ok) return [];
  let body: any;
  try {
    body = await res.json();
  } catch {
    return [];
  }
  const list = body?.data?.list;
  if (!Array.isArray(list)) return [];
  return list as RawStore[];
}

// ============================================================================
// 정규화
// ============================================================================

interface StoreRow {
  store_no: string;
  name: string;
  address: string;
  phone: string | null;
  sido: string | null;
  sigungu: string | null;
  dong: string | null;
  sells_lotto645: boolean;
  sells_pension720: boolean;
  // PostGIS geography(Point, 4326) WKT - 'SRID=4326;POINT(lng lat)' or null
  geom: string | null;
  updated_at: string;
}

function normalize(raw: RawStore): StoreRow | null {
  const storeNo = (raw.ltShpId ?? "").toString().trim();
  const name = (raw.conmNm ?? "").toString().trim();
  if (!storeNo || !name) return null;

  const road = (raw.bplcRdnmDaddr ?? "").toString().trim();
  const jibun = (raw.bplcLctnDaddr ?? "").toString().trim();
  const address = road || jibun;

  const lat = toNum(raw.shpLat);
  const lng = toNum(raw.shpLot);
  const hasGeo =
    lat !== null && lng !== null &&
    Math.abs(lat) > 0.0001 && Math.abs(lng) > 0.0001;

  return {
    store_no: storeNo,
    name,
    address,
    phone: nullIfEmpty(raw.shpTelno),
    sido: nullIfEmpty(raw.tm1BplcLctnAddr),
    sigungu: nullIfEmpty(raw.tm2BplcLctnAddr),
    dong: nullIfEmpty(raw.tm3BplcLctnAddr),
    sells_lotto645: (raw.l645LtNtslYn ?? "").toString().toUpperCase() === "Y",
    sells_pension720: (raw.pt720NtslYn ?? "").toString().toUpperCase() === "Y",
    geom: hasGeo ? `SRID=4326;POINT(${lng} ${lat})` : null,
    updated_at: new Date().toISOString(),
  };
}

function toNum(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  const n = Number(String(v).trim());
  return Number.isFinite(n) ? n : null;
}

function nullIfEmpty(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return s.length === 0 ? null : s;
}

// ============================================================================
// 병렬 페치 (시도 × 시군구)
// ============================================================================

interface Task {
  sido: string;
  sigungu: string;
}

async function crawlAll(): Promise<Map<string, StoreRow>> {
  const tasks: Task[] = [];
  for (const sido of Object.keys(CTPV_MAP)) {
    const sgList = SIGUNGU_MAP[sido] ?? [];
    if (sgList.length === 0) {
      tasks.push({ sido, sigungu: "" });
    } else {
      for (const sg of sgList) tasks.push({ sido, sigungu: sg });
    }
  }

  const merged = new Map<string, StoreRow>();
  const CONCURRENCY = 12;
  // 동행복권 API는 recordCountPerPage 파라미터를 무시하고 페이지당 10개씩 응답한다.
  // 강남구처럼 100개 넘는 시군구도 있으므로 최대 50페이지(=500개)까지 시도.
  const PAGES_PER_SIGUNGU = 50;

  for (let i = 0; i < tasks.length; i += CONCURRENCY) {
    const chunk = tasks.slice(i, i + CONCURRENCY);
    await Promise.all(chunk.map(async (t) => {
      const sidoShort = CTPV_MAP[t.sido] ?? t.sido;
      for (let page = 1; page <= PAGES_PER_SIGUNGU; page++) {
        let list: RawStore[] = [];
        try {
          list = await fetchPage({
            sidoShort,
            sigungu: t.sigungu,
            page,
            only645: true,
          });
        } catch (_) {
          break;
        }
        // 빈 페이지가 마지막 페이지의 유일한 정확한 신호.
        // (응답 개수는 페이지당 10 또는 그 이하라서 length 비교로 끝 판정 못 함)
        if (list.length === 0) break;
        for (const raw of list) {
          const row = normalize(raw);
          if (!row) continue;
          merged.set(row.store_no, row); // 중복 시 마지막 행으로 덮어씀
        }
      }
    }));
  }

  return merged;
}

// ============================================================================
// UPSERT (배치)
// ============================================================================

async function upsertBatched(
  supabase: ReturnType<typeof createClient>,
  rows: StoreRow[],
): Promise<number> {
  const BATCH = 500;
  let total = 0;
  for (let i = 0; i < rows.length; i += BATCH) {
    const slice = rows.slice(i, i + BATCH);
    const { error } = await supabase
      .from("lotto_stores")
      .upsert(slice, { onConflict: "store_no" });
    if (error) {
      console.error("upsert error", error);
      throw error;
    }
    total += slice.length;
  }
  return total;
}

// ============================================================================
// HTTP 핸들러
// ============================================================================

Deno.serve(async (req: Request) => {
  if (req.method !== "POST" && req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const token = req.headers.get("x-cron-token") ?? "";
  if (token !== CRAWL_TOKEN) {
    return new Response("forbidden", { status: 403 });
  }

  const start = Date.now();

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("missing supabase env", { status: 500 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  try {
    const merged = await crawlAll();
    const rows = Array.from(merged.values());
    const inserted = await upsertBatched(supabase, rows);

    const sidos = Object.keys(CTPV_MAP).length;
    const sigungus = Object.values(SIGUNGU_MAP)
      .reduce((acc, v) => acc + v.length, 0);

    return new Response(
      JSON.stringify({
        ok: true,
        inserted_or_updated: inserted,
        sidos,
        sigungus,
        took_ms: Date.now() - start,
      }),
      { headers: { "content-type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: String(e),
        took_ms: Date.now() - start,
      }),
      { status: 500, headers: { "content-type": "application/json" } },
    );
  }
});
