"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Image from "next/image";
import {
  Activity,
  ArrowDown,
  ArrowUp,
  Bell,
  BookOpen,
  CalendarDays,
  CheckCircle2,
  ChevronRight,
  CircleUserRound,
  Eye,
  EyeOff,
  FileQuestion,
  LayoutDashboard,
  Layers3,
  Link2,
  LogOut,
  Mail,
  Pencil,
  Plus,
  RefreshCw,
  Search,
  Server,
  ShieldCheck,
  Trash2,
  Users,
  X,
} from "lucide-react";

type Role = "PARENT" | "CHILD" | "ADULT";
type View = "overview" | "users" | "links" | "tests" | "guides";
type ApiUser = {
  id: string;
  name: string;
  email: string;
  role: Role;
  age: number;
  avatarIndex: number;
  createdAt: string;
  ownedLinks: Array<{ status: string; counterpart?: { name: string } | null }>;
  joinedLinks: Array<{ status: string; owner: { name: string } }>;
};
type ApiLink = {
  id: string;
  inviteCode: string;
  status: "PENDING" | "ACTIVE";
  createdAt: string;
  linkedAt: string | null;
  expiresAt: string;
  owner: { id: string; name: string; email: string; avatarIndex: number };
  counterpart: {
    id: string;
    name: string;
    email: string;
    avatarIndex: number;
  } | null;
};
type Dashboard = {
  users: number;
  activeLinks: number;
  usersByRole: Array<{ role: Role; _count: { _all: number } }>;
  signupsLast7Days: number;
  subscriptions: {
    active: number;
    byStatus: Array<{ status: string; _count: { _all: number } }>;
  };
  testAttempts: {
    total: number;
    completed: number;
    averageScorePercent: number | null;
  };
};
type ApiTest = {
  id: string;
  title: string;
  description: string | null;
  audience: "AGE_6" | "AGE_16" | "AGE_18";
  position: number;
  questionCount: number;
  isPublished: boolean;
  createdAt: string;
  updatedAt: string;
};
type Audience = ApiTest["audience"];
type ApiSection = {
  id: string;
  title: string;
  audience: Audience;
  position: number;
  sourceFile: string;
  isPublished: boolean;
  _count: { questions: number };
};
type ContentSummary = {
  byAudience: Array<{
    audience: Audience;
    sections: number;
    sectionQuestions: number;
    tests: number;
    testQuestions: number;
    publishedTests: number;
  }>;
  guideCount: number;
};
type ApiGuide = {
  id: string;
  slug: string;
  title: string;
  sourceFile: string;
  pageCount: number;
  updatedAt: string;
};
type GuideDetail = ApiGuide & {
  content: {
    intro: string;
    sections: Array<{ position: number; title: string; text: string }>;
    fullText: string;
  };
};
type ApiTestQuestion = {
  id: string;
  position: number;
  material: string | null;
  text: string;
  options: string[];
  correctOption: number;
  section: { id: string; title: string; position: number } | null;
};
type TestDetail = ApiTest & {
  questions: ApiTestQuestion[];
};

const API = "/api/admin";
const roleLabels: Record<Role, string> = {
  PARENT: "Родитель",
  CHILD: "Ребёнок",
  ADULT: "Взрослый",
};
const avatarFiles = [
  "00_boy_green",
  "01_girl_pigtails_pink",
  "02_boy_glasses_blue",
  "03_girl_blonde_lavender",
  "04_boy_cap_red",
  "05_girl_ponytail_purple",
  "06_boy_curly_green",
  "07_girl_black_yellow",
  "08_dragon_green",
  "09_robot_purple",
  "10_star_yellow",
  "11_monster_blue",
];
const avatar = (index: number) =>
  `/avatars/${avatarFiles[Math.max(0, Math.min(11, index))]}.png?v=figma-108`;
const formatDate = (value: string) =>
  new Intl.DateTimeFormat("ru-RU", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
const audienceLabel = (audience: Audience) =>
  audience === "AGE_6" ? "6+" : audience === "AGE_16" ? "16+" : "18+";

const nav: Array<{ id: View; label: string; icon: typeof LayoutDashboard }> = [
  { id: "overview", label: "Обзор", icon: LayoutDashboard },
  { id: "users", label: "Пользователи", icon: Users },
  { id: "links", label: "Связки", icon: Link2 },
  { id: "tests", label: "Тесты", icon: FileQuestion },
  { id: "guides", label: "Материалы", icon: BookOpen },
];

export default function AdminPage() {
  const [view, setView] = useState<View>("overview");
  const [users, setUsers] = useState<ApiUser[]>([]);
  const [links, setLinks] = useState<ApiLink[]>([]);
  const [dashboard, setDashboard] = useState<Dashboard | null>(null);
  const [tests, setTests] = useState<ApiTest[]>([]);
  const [sections, setSections] = useState<ApiSection[]>([]);
  const [contentSummary, setContentSummary] = useState<ContentSummary | null>(
    null,
  );
  const [guides, setGuides] = useState<ApiGuide[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [query, setQuery] = useState("");
  const [role, setRole] = useState<"ALL" | Role>("ALL");
  const [selected, setSelected] = useState<ApiUser | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const responses = await Promise.all(
        [
          "dashboard",
          "users",
          "links",
          "tests",
          "content/summary",
          "sections",
          "guides",
        ].map((path) => fetch(`${API}/${path}`)),
      );
      if (responses.some((response) => !response.ok))
        throw new Error("backend");
      const [
        stats,
        userRows,
        linkRows,
        testRows,
        contentStats,
        sectionRows,
        guideRows,
      ] = await Promise.all(responses.map((response) => response.json()));
      setDashboard(stats);
      setUsers(userRows);
      setLinks(linkRows);
      setTests(testRows);
      setContentSummary(contentStats);
      setSections(sectionRows);
      setGuides(guideRows);
      setError("");
    } catch {
      setError(
        "Не удалось получить данные. Обновите страницу или повторите позже.",
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = window.setTimeout(() => void load(), 0);
    return () => window.clearTimeout(timer);
  }, [load]);

  const logout = useCallback(async () => {
    if (!window.confirm("Выйти из админки?")) return;
    try {
      // Force the browser to forget cached Basic Auth credentials by
      // deliberately failing auth once, then reload to the challenge.
      await fetch(window.location.pathname, {
        headers: { Authorization: "Basic " + btoa(`logout:${Date.now()}`) },
        cache: "no-store",
      });
    } catch {
      // ignore — reload below still prompts for credentials in most browsers
    }
    window.location.reload();
  }, []);

  const filtered = useMemo(
    () =>
      users.filter((user) => {
        const text = `${user.name} ${user.email}`.toLowerCase();
        return (
          text.includes(query.toLowerCase()) &&
          (role === "ALL" || user.role === role)
        );
      }),
    [users, query, role],
  );

  const countRole = (value: Role) =>
    dashboard?.usersByRole.find((row) => row.role === value)?._count._all ?? 0;
  const pageTitle = nav.find((item) => item.id === view)?.label ?? "Обзор";

  return (
    <div className="app-shell">
      <aside className="side-nav">
        <div className="logo">
          <span>А</span>
          <div>
            Антисмок<small>управление</small>
          </div>
        </div>
        <nav aria-label="Разделы админки">
          {nav.map((item) => (
            <button
              key={item.id}
              className={view === item.id ? "selected" : ""}
              onClick={() => setView(item.id)}
              aria-label={item.label}
            >
              <item.icon />
              <span>{item.label}</span>
              {item.id === "links" && links.length > 0 && <b>{links.length}</b>}
            </button>
          ))}
        </nav>
        <button
          type="button"
          className="admin-identity"
          onClick={() => void logout()}
          title="Выйти"
          aria-label="Выйти"
        >
          <LogOut />
          <span>Выйти</span>
        </button>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <div>
            <p className="eyebrow">Антисмок</p>
            <h1>{pageTitle}</h1>
            <p>
              {view === "overview"
                ? "Состояние платформы на текущий момент"
                : view === "users"
                  ? "Все зарегистрированные аккаунты"
                  : view === "links"
                    ? "Связи родителей и детей"
                    : view === "tests"
                      ? "Создание и публикация тестов"
                      : "Советы и обучающие материалы"}
            </p>
          </div>
          <div className="top-actions">
            <button className="round-button" aria-label="Уведомления">
              <Bell />
            </button>
            <button
              className="refresh-button"
              onClick={() => void load()}
              disabled={loading}
            >
              <RefreshCw className={loading ? "spinning" : ""} />
              <span>Обновить</span>
            </button>
          </div>
        </header>

        {error && (
          <div className="error-banner">
            <Server />
            {error}
          </div>
        )}
        {view === "overview" && (
          <Overview
            dashboard={dashboard}
            users={users}
            links={links}
            loading={loading}
            onUser={setSelected}
            onNavigate={setView}
            countRole={countRole}
          />
        )}
        {view === "users" && (
          <UsersView
            users={filtered}
            allCount={users.length}
            query={query}
            setQuery={setQuery}
            role={role}
            setRole={setRole}
            loading={loading}
            onUser={setSelected}
          />
        )}
        {view === "links" && <LinksView links={links} loading={loading} />}
        {view === "tests" && (
          <TestsView
            tests={tests}
            sections={sections}
            summary={contentSummary}
            guides={guides}
            loading={loading}
            reload={load}
          />
        )}
        {view === "guides" && (
          <GuidesView guides={guides} loading={loading} reload={load} />
        )}
      </main>

      {selected && (
        <UserDrawer
          user={selected}
          links={links}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}

function Overview({
  dashboard,
  users,
  links,
  loading,
  onUser,
  onNavigate,
  countRole,
}: {
  dashboard: Dashboard | null;
  users: ApiUser[];
  links: ApiLink[];
  loading: boolean;
  onUser: (user: ApiUser) => void;
  onNavigate: (view: View) => void;
  countRole: (role: Role) => number;
}) {
  const total = dashboard?.users ?? 0;
  const active = dashboard?.activeLinks ?? 0;
  const recent = users.slice(0, 4);
  return (
    <div className="page-stack">
      <section className="stats-grid">
        <Stat
          icon={Users}
          tone="blue"
          value={total}
          label="Пользователей"
          note="в базе данных"
          loading={loading}
        />
        <Stat
          icon={Link2}
          tone="purple"
          value={active}
          label="Активных связок"
          note={`из ${links.length} всего`}
          loading={loading}
        />
        <Stat
          icon={CircleUserRound}
          tone="orange"
          value={countRole("PARENT")}
          label="Родителей"
          note="зарегистрировано"
          loading={loading}
        />
        <Stat
          icon={ShieldCheck}
          tone="green"
          value={countRole("CHILD")}
          label="Детей"
          note="зарегистрировано"
          loading={loading}
        />
        <Stat
          icon={CheckCircle2}
          tone="blue"
          value={dashboard?.subscriptions.active ?? 0}
          label="Активных Premium"
          note="подписок"
          loading={loading}
        />
        <Stat
          icon={FileQuestion}
          tone="purple"
          value={dashboard?.testAttempts.completed ?? 0}
          label="Тестов пройдено"
          note={`из ${dashboard?.testAttempts.total ?? 0} попыток`}
          loading={loading}
        />
        <Stat
          icon={Activity}
          tone="orange"
          value={dashboard?.testAttempts.averageScorePercent ?? 0}
          label="Средний результат"
          note="% правильных ответов"
          loading={loading}
        />
        <Stat
          icon={CalendarDays}
          tone="green"
          value={dashboard?.signupsLast7Days ?? 0}
          label="Новых за 7 дней"
          note="регистраций"
          loading={loading}
        />
      </section>

      <section className="overview-grid">
        <article className="card role-card">
          <div className="card-heading">
            <div>
              <span className="section-kicker">Аудитория</span>
              <h2>Роли пользователей</h2>
            </div>
          </div>
          <div className="role-visual">
            <div className="role-ring">
              <div>
                <strong>{total}</strong>
                <span>всего</span>
              </div>
            </div>
            <div className="role-legend">
              <p>
                <i className="parent" />
                Родители <b>{countRole("PARENT")}</b>
              </p>
              <p>
                <i className="child" />
                Дети <b>{countRole("CHILD")}</b>
              </p>
              <p>
                <i className="adult" />
                Взрослые <b>{countRole("ADULT")}</b>
              </p>
            </div>
          </div>
        </article>

        <section className="card recent-card">
          <div className="card-heading">
            <div>
              <span className="section-kicker">Последние регистрации</span>
              <h2>Новые пользователи</h2>
            </div>
            <button
              className="text-button"
              onClick={() => onNavigate("users")}
            >
              Смотреть всех <ChevronRight />
            </button>
          </div>
          <div className="recent-list">
            {recent.map((user) => (
              <button
                key={user.id}
                className="recent-user"
                onClick={() => onUser(user)}
              >
                <Avatar user={user} />
                <div>
                  <strong>{user.name}</strong>
                  <span>{user.email}</span>
                </div>
                <RoleBadge role={user.role} />
                <time>{formatDate(user.createdAt)}</time>
                <ChevronRight />
              </button>
            ))}
            {!loading && recent.length === 0 && (
              <Empty text="Пользователей пока нет" />
            )}
          </div>
        </section>
      </section>
    </div>
  );
}

function UsersView({
  users,
  allCount,
  query,
  setQuery,
  role,
  setRole,
  loading,
  onUser,
}: {
  users: ApiUser[];
  allCount: number;
  query: string;
  setQuery: (value: string) => void;
  role: "ALL" | Role;
  setRole: (value: "ALL" | Role) => void;
  loading: boolean;
  onUser: (user: ApiUser) => void;
}) {
  return (
    <section className="card directory-card">
      <div className="directory-head">
        <div>
          <span className="section-kicker">База аккаунтов</span>
          <h2>{allCount} пользователей</h2>
        </div>
      </div>
      <div className="filters">
        <label>
          <Search />
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Имя или email"
          />
        </label>
        <div className="segmented">
          {(["ALL", "PARENT", "CHILD", "ADULT"] as const).map((item) => (
            <button
              className={role === item ? "active" : ""}
              key={item}
              onClick={() => setRole(item)}
            >
              {item === "ALL" ? "Все" : roleLabels[item]}
            </button>
          ))}
        </div>
      </div>
      <div className="desktop-table">
        <div className="table-head">
          <span>Пользователь</span>
          <span>Роль</span>
          <span>Возраст</span>
          <span>Регистрация</span>
          <span />
        </div>
        {users.map((user) => (
          <button
            className="table-row"
            key={user.id}
            onClick={() => onUser(user)}
          >
            <UserIdentity user={user} />
            <RoleBadge role={user.role} />
            <span>{user.age} лет</span>
            <span>{formatDate(user.createdAt)}</span>
            <ChevronRight />
          </button>
        ))}
      </div>
      <div className="mobile-users">
        {users.map((user) => (
          <button
            className="mobile-user-card"
            key={user.id}
            onClick={() => onUser(user)}
          >
            <UserIdentity user={user} />
            <ChevronRight />
            <div>
              <RoleBadge role={user.role} />
              <span>{user.age} лет</span>
              <span>{formatDate(user.createdAt)}</span>
            </div>
          </button>
        ))}
      </div>
      {!loading && users.length === 0 && (
        <Empty text="По этому фильтру ничего не найдено" />
      )}
      {loading && <LoadingRows />}
    </section>
  );
}

function LinksView({ links, loading }: { links: ApiLink[]; loading: boolean }) {
  return (
    <section className="links-layout">
      <div className="links-summary">
        <div>
          <Link2 />
          <span>
            <strong>{links.length}</strong>Всего связок
          </span>
        </div>
        <div>
          <CheckCircle2 />
          <span>
            <strong>
              {links.filter((link) => link.status === "ACTIVE").length}
            </strong>
            Активные
          </span>
        </div>
      </div>
      <div className="card links-table-wrap">
        <table className="links-table">
          <thead>
            <tr>
              <th>Родитель</th>
              <th>Ребёнок</th>
              <th>Статус</th>
              <th className="optional-col">Дата связки</th>
              <th className="optional-col">Код</th>
            </tr>
          </thead>
          <tbody>
            {links.map((link) => (
              <tr key={link.id}>
                <td>
                  <Person person={link.owner} />
                </td>
                <td>
                  {link.counterpart ? (
                    <Person person={link.counterpart} />
                  ) : (
                    <span className="not-linked">
                      <CircleUserRound />
                      Не подключён
                    </span>
                  )}
                </td>
                <td>
                  <span
                    className={`table-status ${link.status === "ACTIVE" ? "active" : "pending"}`}
                  >
                    <i />
                    {link.status === "ACTIVE" ? "Активна" : "Ожидает"}
                  </span>
                </td>
                <td className="optional-col">
                  {formatDate(link.linkedAt ?? link.createdAt)}
                </td>
                <td className="optional-col">
                  <code>{link.inviteCode}</code>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!loading && links.length === 0 && (
          <Empty text="Связок аккаунтов пока нет" />
        )}
        {loading && <LoadingRows />}
      </div>
    </section>
  );
}

function TestsView({
  tests,
  sections,
  summary,
  guides,
  loading,
  reload,
}: {
  tests: ApiTest[];
  sections: ApiSection[];
  summary: ContentSummary | null;
  guides: ApiGuide[];
  loading: boolean;
  reload: () => Promise<void>;
}) {
  const [mode, setMode] = useState<"tests" | "sections" | "guide">("tests");
  const [audienceFilter, setAudienceFilter] = useState<"ALL" | Audience>("ALL");
  const [creating, setCreating] = useState(false);
  const [saving, setSaving] = useState(false);
  const [moving, setMoving] = useState(false);
  const [moveError, setMoveError] = useState("");
  const [selectedTest, setSelectedTest] = useState<TestDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [guide, setGuide] = useState<GuideDetail | null>(null);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [audience, setAudience] = useState<ApiTest["audience"]>("AGE_6");
  const visibleTests = tests
    .filter(
      (test) => audienceFilter === "ALL" || test.audience === audienceFilter,
    )
    .sort((a, b) => a.position - b.position || a.title.localeCompare(b.title));
  const visibleSections = sections
    .filter(
      (section) =>
        audienceFilter === "ALL" || section.audience === audienceFilter,
    )
    .sort((a, b) => a.position - b.position);
  const openTest = async (id: string) => {
    setDetailLoading(true);
    const response = await fetch(`${API}/tests/${id}`);
    if (response.ok) setSelectedTest(await response.json());
    setDetailLoading(false);
  };
  const openGuide = async (slug: string) => {
    const response = await fetch(`${API}/guides/${slug}`);
    if (response.ok) setGuide(await response.json());
  };
  const create = async (event: React.FormEvent) => {
    event.preventDefault();
    setSaving(true);
    const response = await fetch(`${API}/tests`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        title,
        description: description || undefined,
        audience,
      }),
    });
    setSaving(false);
    if (!response.ok) return;
    setTitle("");
    setDescription("");
    setAudience("AGE_6");
    setCreating(false);
    await reload();
  };
  const toggle = async (test: ApiTest) => {
    await fetch(`${API}/tests/${test.id}`, {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ isPublished: !test.isPublished }),
    });
    await reload();
  };
  const moveTest = async (test: ApiTest, direction: "UP" | "DOWN") => {
    setMoving(true);
    setMoveError("");
    const response = await fetch(`${API}/tests/${test.id}/move`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ direction }),
    });
    if (!response.ok) {
      setMoveError("Не удалось изменить порядок теста");
      setMoving(false);
      return;
    }
    await reload();
    setMoving(false);
  };
  const moveSection = async (section: ApiSection, direction: "UP" | "DOWN") => {
    setMoving(true);
    setMoveError("");
    const response = await fetch(`${API}/sections/${section.id}/move`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ direction }),
    });
    if (!response.ok) {
      setMoveError("Не удалось изменить порядок раздела");
      setMoving(false);
      return;
    }
    await reload();
    setMoving(false);
  };
  const canMoveTest = (test: ApiTest, direction: "UP" | "DOWN") => {
    const group = visibleTests.filter((item) => item.audience === test.audience);
    const index = group.findIndex((item) => item.id === test.id);
    return direction === "UP" ? index > 0 : index < group.length - 1;
  };
  const canMoveSection = (section: ApiSection, direction: "UP" | "DOWN") => {
    const group = visibleSections.filter(
      (item) => item.audience === section.audience,
    );
    const index = group.findIndex((item) => item.id === section.id);
    return direction === "UP" ? index > 0 : index < group.length - 1;
  };
  return (
    <div className="tests-page">
      <section className="content-age-grid">
        {(summary?.byAudience ?? []).map((item) => (
          <button
            key={item.audience}
            className={audienceFilter === item.audience ? "active" : ""}
            onClick={() =>
              setAudienceFilter((current) =>
                current === item.audience ? "ALL" : item.audience,
              )
            }
          >
            <strong>{audienceLabel(item.audience)}</strong>
            <span>{item.sections} разделов</span>
            <small>
              {item.tests} тестов · {item.testQuestions} вопросов
            </small>
          </button>
        ))}
        <button className="create-test" onClick={() => setCreating(true)}>
          <Plus />
          Новый тест
        </button>
      </section>
      <section className="card tests-table-card">
        <div className="tests-toolbar">
          <div>
            <span className="section-kicker">Контент приложения</span>
            <h2>
              {mode === "tests"
                ? "Каталог тестов"
                : mode === "sections"
                  ? "Разделы и банк вопросов"
                  : "Памятка и советы"}
            </h2>
          </div>
          <div className="content-tabs" role="tablist">
            <button
              className={mode === "tests" ? "active" : ""}
              onClick={() => setMode("tests")}
            >
              <FileQuestion />
              Тесты
            </button>
            <button
              className={mode === "sections" ? "active" : ""}
              onClick={() => setMode("sections")}
            >
              <Layers3 />
              Разделы
            </button>
            <button
              className={mode === "guide" ? "active" : ""}
              onClick={() => setMode("guide")}
            >
              <BookOpen />
              Памятка
            </button>
          </div>
        </div>
        {moveError && <div className="error-banner">{moveError}</div>}
        {mode === "tests" && (
          <div className="tests-table-wrap">
            <table className="tests-table">
              <thead>
                <tr>
                  <th>Порядок</th>
                  <th>Название</th>
                  <th>Категория</th>
                  <th>Вопросы</th>
                  <th>Статус</th>
                  <th>Обновлён</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {visibleTests.map((test) => (
                  <tr key={test.id}>
                    <td>
                      <div className="order-controls">
                        <span>{test.position}</span>
                        <button
                          onClick={() => void moveTest(test, "UP")}
                          disabled={moving || !canMoveTest(test, "UP")}
                          aria-label="Поднять тест"
                        >
                          <ArrowUp />
                        </button>
                        <button
                          onClick={() => void moveTest(test, "DOWN")}
                          disabled={moving || !canMoveTest(test, "DOWN")}
                          aria-label="Опустить тест"
                        >
                          <ArrowDown />
                        </button>
                      </div>
                    </td>
                    <td>
                      <button
                        className="test-title-button"
                        onClick={() => void openTest(test.id)}
                      >
                        <strong>{test.title}</strong>
                        <span>{test.description || "Без описания"}</span>
                      </button>
                    </td>
                    <td>{audienceLabel(test.audience)}</td>
                    <td>{test.questionCount}</td>
                    <td>
                      <span
                        className={`test-state ${test.isPublished ? "published" : "draft"}`}
                      >
                        <i />
                        {test.isPublished ? "Опубликован" : "Черновик"}
                      </span>
                    </td>
                    <td>{formatDate(test.updatedAt)}</td>
                    <td>
                      <button
                        className="publish-button"
                        onClick={() => void toggle(test)}
                        aria-label={
                          test.isPublished
                            ? "Снять с публикации"
                            : "Опубликовать"
                        }
                      >
                        {test.isPublished ? <EyeOff /> : <Eye />}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {!loading && visibleTests.length === 0 && (
              <div className="tests-empty">
                <span>
                  <FileQuestion />
                </span>
                <h3>Тестов пока нет</h3>
                <p>Создайте первый тест — он сохранится как черновик.</p>
                <button
                  className="create-test"
                  onClick={() => setCreating(true)}
                >
                  <Plus />
                  Создать тест
                </button>
              </div>
            )}
            {loading && <LoadingRows />}
          </div>
        )}
        {mode === "sections" && (
          <div className="sections-library">
            {visibleSections.map((section) => (
              <article key={section.id}>
                <span>{audienceLabel(section.audience)}</span>
                <div>
                  <small>Раздел {section.position}</small>
                  <h3>{section.title}</h3>
                  <p>{section._count.questions} вопросов в банке</p>
                </div>
                <div className="order-controls section-order">
                  <button
                    onClick={() => void moveSection(section, "UP")}
                    disabled={moving || !canMoveSection(section, "UP")}
                    aria-label="Поднять раздел"
                  >
                    <ArrowUp />
                  </button>
                  <button
                    onClick={() => void moveSection(section, "DOWN")}
                    disabled={moving || !canMoveSection(section, "DOWN")}
                    aria-label="Опустить раздел"
                  >
                    <ArrowDown />
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
        {mode === "guide" && (
          <div className="guides-library">
            {guides.map((item) => (
              <article key={item.id}>
                <div className="guide-icon">
                  <BookOpen />
                </div>
                <div>
                  <span className="section-kicker">Для родителей</span>
                  <h3>{item.title}</h3>
                  <p>{item.pageCount} страниц · советы и рекомендации</p>
                </div>
                <button onClick={() => void openGuide(item.slug)}>
                  Читать <ChevronRight />
                </button>
              </article>
            ))}
          </div>
        )}
      </section>
      {detailLoading && <div className="detail-loading">Загружаю тест…</div>}
      {selectedTest && (
        <TestEditorDrawer
          key={`${selectedTest.id}-${selectedTest.updatedAt}`}
          test={selectedTest}
          sections={sections.filter(
            (section) => section.audience === selectedTest.audience,
          )}
          onClose={() => setSelectedTest(null)}
          onChanged={reload}
          onTest={setSelectedTest}
        />
      )}
      {guide && (
        <div
          className="content-drawer-backdrop"
          onMouseDown={() => setGuide(null)}
        >
          <aside
            className="content-drawer guide-drawer"
            onMouseDown={(event) => event.stopPropagation()}
          >
            <button
              className="drawer-close"
              onClick={() => setGuide(null)}
              aria-label="Закрыть"
            >
              <X />
            </button>
            <span className="section-kicker">
              Памятка · {guide.pageCount} страниц
            </span>
            <h2>{guide.title}</h2>
            <div className="guide-content">
              {guide.content.sections.map((section) => (
                <article key={section.position}>
                  <span>{section.position}</span>
                  <div>
                    <h3>{section.title}</h3>
                    <p>{section.text}</p>
                  </div>
                </article>
              ))}
            </div>
          </aside>
        </div>
      )}
      {creating && (
        <div
          className="test-modal-backdrop"
          onMouseDown={() => setCreating(false)}
        >
          <form
            className="test-modal"
            onSubmit={create}
            onMouseDown={(event) => event.stopPropagation()}
          >
            <button
              type="button"
              className="drawer-close"
              onClick={() => setCreating(false)}
              aria-label="Закрыть"
            >
              <X />
            </button>
            <span className="section-kicker">Новый тест</span>
            <h2>Основная информация</h2>
            <label>
              Название
              <input
                required
                maxLength={120}
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                placeholder="Например, Мой выбор"
              />
            </label>
            <label>
              Описание
              <textarea
                maxLength={500}
                value={description}
                onChange={(event) => setDescription(event.target.value)}
                placeholder="Коротко опишите содержание теста"
              />
            </label>
            <label>
              Возрастная категория
              <select
                value={audience}
                onChange={(event) =>
                  setAudience(event.target.value as ApiTest["audience"])
                }
              >
                <option value="AGE_6">6+</option>
                <option value="AGE_16">16+</option>
                <option value="AGE_18">18+</option>
              </select>
            </label>
            <button className="create-test submit" disabled={saving}>
              {saving ? "Сохраняю…" : "Создать черновик"}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}

function GuidesView({
  guides,
  loading,
  reload,
}: {
  guides: ApiGuide[];
  loading: boolean;
  reload: () => Promise<void>;
}) {
  const [editingSlug, setEditingSlug] = useState<string | null>(null);
  const [guide, setGuide] = useState<GuideDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const open = async (slug: string) => {
    setEditingSlug(slug);
    setDetailLoading(true);
    const response = await fetch(`${API}/guides/${slug}`);
    if (response.ok) setGuide(await response.json());
    setDetailLoading(false);
  };

  return (
    <div className="page-stack">
      <section className="card recent-card">
        <div className="card-heading">
          <div>
            <span className="section-kicker">Советы и обучающие материалы</span>
            <h2>{guides.length} материалов</h2>
          </div>
        </div>
        <div className="guides-library">
          {guides.map((item) => (
            <article key={item.id}>
              <div className="guide-icon">
                <BookOpen />
              </div>
              <div>
                <span className="section-kicker">{item.slug}</span>
                <h3>{item.title}</h3>
                <p>
                  {item.pageCount} страниц · обновлено{" "}
                  {formatDate(item.updatedAt)}
                </p>
              </div>
              <button onClick={() => void open(item.slug)}>
                <Pencil /> Редактировать
              </button>
            </article>
          ))}
          {!loading && guides.length === 0 && (
            <Empty text="Материалов пока нет" />
          )}
        </div>
      </section>
      {detailLoading && <div className="detail-loading">Загружаю материал…</div>}
      {editingSlug && guide && (
        <GuideEditorDrawer
          key={`${guide.slug}-${guide.updatedAt}`}
          guide={guide}
          onClose={() => {
            setEditingSlug(null);
            setGuide(null);
          }}
          onSaved={async () => {
            setEditingSlug(null);
            setGuide(null);
            await reload();
          }}
        />
      )}
    </div>
  );
}

function GuideEditorDrawer({
  guide,
  onClose,
  onSaved,
}: {
  guide: GuideDetail;
  onClose: () => void;
  onSaved: () => Promise<void>;
}) {
  const [title, setTitle] = useState(guide.title);
  const [intro, setIntro] = useState(guide.content.intro);
  const [fullText, setFullText] = useState(guide.content.fullText);
  const [sections, setSections] = useState(
    guide.content.sections.map((section) => ({ ...section })),
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const updateSection = (
    index: number,
    field: "title" | "text",
    value: string,
  ) => {
    setSections((current) =>
      current.map((section, i) =>
        i === index ? { ...section, [field]: value } : section,
      ),
    );
  };

  const save = async (event: React.FormEvent) => {
    event.preventDefault();
    setSaving(true);
    setError("");
    const response = await fetch(`${API}/guides/${guide.slug}`, {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        title,
        content: { intro, fullText, sections },
      }),
    });
    setSaving(false);
    if (!response.ok) {
      setError("Не удалось сохранить материал. Проверьте поля и повторите.");
      return;
    }
    await onSaved();
  };

  return (
    <div className="content-drawer-backdrop" onMouseDown={onClose}>
      <form
        className="content-drawer guide-drawer"
        onSubmit={save}
        onMouseDown={(event) => event.stopPropagation()}
      >
        <button
          type="button"
          className="drawer-close"
          onClick={onClose}
          aria-label="Закрыть"
        >
          <X />
        </button>
        <span className="section-kicker">Материал · {guide.slug}</span>
        <label>
          Заголовок
          <input
            required
            maxLength={200}
            value={title}
            onChange={(event) => setTitle(event.target.value)}
          />
        </label>
        <label>
          Вступление
          <textarea
            maxLength={2000}
            value={intro}
            onChange={(event) => setIntro(event.target.value)}
          />
        </label>
        <div className="guide-content">
          {sections.map((section, index) => (
            <article key={section.position}>
              <span>{section.position}</span>
              <div>
                <input
                  maxLength={200}
                  value={section.title}
                  onChange={(event) =>
                    updateSection(index, "title", event.target.value)
                  }
                />
                <textarea
                  maxLength={10000}
                  value={section.text}
                  onChange={(event) =>
                    updateSection(index, "text", event.target.value)
                  }
                />
              </div>
            </article>
          ))}
        </div>
        <label>
          Полный текст
          <textarea
            maxLength={50000}
            value={fullText}
            onChange={(event) => setFullText(event.target.value)}
          />
        </label>
        {error && <div className="error-banner">{error}</div>}
        <button className="create-test submit" disabled={saving}>
          {saving ? "Сохраняю…" : "Сохранить изменения"}
        </button>
      </form>
    </div>
  );
}

type QuestionDraft = {
  id?: string;
  material: string;
  text: string;
  options: string[];
  correctOption: number;
  sectionId: string | null;
};

function TestEditorDrawer({
  test,
  sections,
  onClose,
  onChanged,
  onTest,
}: {
  test: TestDetail;
  sections: ApiSection[];
  onClose: () => void;
  onChanged: () => Promise<void>;
  onTest: (test: TestDetail | null) => void;
}) {
  const [title, setTitle] = useState(test.title);
  const [description, setDescription] = useState(test.description ?? "");
  const [audience, setAudience] = useState<Audience>(test.audience);
  const [published, setPublished] = useState(test.isPublished);
  const [question, setQuestion] = useState<QuestionDraft | null>(null);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  const refresh = async () => {
    const response = await fetch(`${API}/tests/${test.id}`);
    if (!response.ok) throw new Error("refresh");
    onTest(await response.json());
    await onChanged();
  };

  const saveMetadata = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setNotice("");
    const response = await fetch(`${API}/tests/${test.id}`, {
      method: "PATCH",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        title: title.trim(),
        description: description.trim(),
        audience,
        isPublished: published,
      }),
    });
    if (response.ok) {
      await refresh();
      setNotice("Изменения сохранены");
    } else {
      setNotice("Не удалось сохранить изменения");
    }
    setBusy(false);
  };

  const removeTest = async () => {
    if (!window.confirm(`Удалить тест «${test.title}» вместе с вопросами?`))
      return;
    setBusy(true);
    const response = await fetch(`${API}/tests/${test.id}`, {
      method: "DELETE",
    });
    if (response.ok) {
      onTest(null);
      await onChanged();
      return;
    }
    setNotice("Не удалось удалить тест");
    setBusy(false);
  };

  const startQuestion = (current?: ApiTestQuestion) => {
    setQuestion(
      current
        ? {
            id: current.id,
            material: current.material ?? "",
            text: current.text,
            options: [...current.options],
            correctOption: current.correctOption,
            sectionId: current.section?.id ?? null,
          }
        : {
            material: "",
            text: "",
            options: ["", "", "", ""],
            correctOption: 1,
            sectionId: null,
          },
    );
  };

  const saveQuestion = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!question) return;
    const options = question.options.map((option) => option.trim());
    if (options.some((option) => !option)) {
      setNotice("Заполните все варианты ответа");
      return;
    }
    setBusy(true);
    setNotice("");
    const response = await fetch(
      question.id
        ? `${API}/tests/${test.id}/questions/${question.id}`
        : `${API}/tests/${test.id}/questions`,
      {
        method: question.id ? "PATCH" : "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          material: question.material.trim(),
          text: question.text.trim(),
          options,
          correctOption: question.correctOption,
          sectionId: question.sectionId,
        }),
      },
    );
    if (response.ok) {
      setQuestion(null);
      await refresh();
      setNotice("Вопрос сохранён");
    } else {
      setNotice("Не удалось сохранить вопрос");
    }
    setBusy(false);
  };

  const removeQuestion = async (current: ApiTestQuestion) => {
    if (!window.confirm(`Удалить вопрос ${current.position}?`)) return;
    setBusy(true);
    const response = await fetch(
      `${API}/tests/${test.id}/questions/${current.id}`,
      { method: "DELETE" },
    );
    if (response.ok) await refresh();
    else setNotice("Не удалось удалить вопрос");
    setBusy(false);
  };

  const moveQuestion = async (
    current: ApiTestQuestion,
    direction: "UP" | "DOWN",
  ) => {
    setBusy(true);
    const response = await fetch(
      `${API}/tests/${test.id}/questions/${current.id}/move`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ direction }),
      },
    );
    if (response.ok) await refresh();
    else setNotice("Не удалось изменить порядок");
    setBusy(false);
  };

  return (
    <div className="content-drawer-backdrop" onMouseDown={onClose}>
      <aside
        className="content-drawer test-editor-drawer"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <button className="drawer-close" onClick={onClose} aria-label="Закрыть">
          <X />
        </button>
        <span className="section-kicker">Редактор теста</span>
        <h2>{test.title}</h2>

        <form className="test-editor-meta" onSubmit={saveMetadata}>
          <label>
            Название
            <input
              required
              maxLength={120}
              value={title}
              onChange={(event) => setTitle(event.target.value)}
            />
          </label>
          <label>
            Описание
            <textarea
              maxLength={500}
              value={description}
              onChange={(event) => setDescription(event.target.value)}
            />
          </label>
          <div className="test-editor-meta-row">
            <label>
              Категория
              <select
                value={audience}
                onChange={(event) =>
                  setAudience(event.target.value as Audience)
                }
              >
                <option value="AGE_6">6+</option>
                <option value="AGE_16">16+</option>
                <option value="AGE_18">18+</option>
              </select>
            </label>
            <label>
              Статус
              <select
                value={published ? "PUBLISHED" : "DRAFT"}
                onChange={(event) =>
                  setPublished(event.target.value === "PUBLISHED")
                }
              >
                <option value="DRAFT">Черновик</option>
                <option value="PUBLISHED">Опубликован</option>
              </select>
            </label>
          </div>
          <div className="test-editor-actions">
            <button className="create-test" disabled={busy}>
              {busy ? "Сохраняю…" : "Сохранить тест"}
            </button>
            <button
              type="button"
              className="danger-button"
              onClick={() => void removeTest()}
              disabled={busy}
            >
              <Trash2 /> Удалить
            </button>
          </div>
        </form>

        <div className="question-section-heading">
          <div>
            <span className="section-kicker">Содержание</span>
            <h3>{test.questions.length} вопросов</h3>
          </div>
          <button className="create-test" onClick={() => startQuestion()}>
            <Plus /> Добавить вопрос
          </button>
        </div>
        {notice && <p className="editor-notice">{notice}</p>}
        <div className="question-list editable">
          {test.questions.map((current, index) => (
            <article key={current.id}>
              <div className="question-card-heading">
                <small>
                  Вопрос {current.position}
                  {current.section ? ` · ${current.section.title}` : ""}
                </small>
                <div>
                  <button
                    onClick={() => void moveQuestion(current, "UP")}
                    disabled={busy || index === 0}
                    aria-label="Поднять вопрос"
                  >
                    <ArrowUp />
                  </button>
                  <button
                    onClick={() => void moveQuestion(current, "DOWN")}
                    disabled={busy || index === test.questions.length - 1}
                    aria-label="Опустить вопрос"
                  >
                    <ArrowDown />
                  </button>
                  <button
                    onClick={() => startQuestion(current)}
                    aria-label="Редактировать вопрос"
                  >
                    <Pencil />
                  </button>
                  <button
                    className="danger"
                    onClick={() => void removeQuestion(current)}
                    disabled={busy}
                    aria-label="Удалить вопрос"
                  >
                    <Trash2 />
                  </button>
                </div>
              </div>
              {current.material && (
                <p className="question-material">{current.material}</p>
              )}
              <h3>{current.text}</h3>
              <ol>
                {current.options.map((option, index) => (
                  <li
                    className={
                      current.correctOption === index + 1 ? "correct" : ""
                    }
                    key={`${current.id}-${index}`}
                  >
                    <span>{index + 1}</span>
                    {option}
                    {current.correctOption === index + 1 && <CheckCircle2 />}
                  </li>
                ))}
              </ol>
            </article>
          ))}
          {test.questions.length === 0 && (
            <div className="editor-empty">
              <FileQuestion />
              <p>Добавьте вопросы перед публикацией теста.</p>
            </div>
          )}
        </div>

        {question && (
          <div
            className="test-modal-backdrop question-editor-backdrop"
            onMouseDown={() => setQuestion(null)}
          >
            <form
              className="test-modal question-editor-modal"
              onSubmit={saveQuestion}
              onMouseDown={(event) => event.stopPropagation()}
            >
              <button
                type="button"
                className="drawer-close"
                onClick={() => setQuestion(null)}
                aria-label="Закрыть"
              >
                <X />
              </button>
              <span className="section-kicker">
                {question.id ? "Редактирование" : "Новый вопрос"}
              </span>
              <h2>Вопрос и ответы</h2>
              <label>
                Материал или пояснение
                <textarea
                  value={question.material}
                  onChange={(event) =>
                    setQuestion({ ...question, material: event.target.value })
                  }
                  placeholder="Необязательно"
                />
              </label>
              <label>
                Тема (раздел)
                <select
                  value={question.sectionId ?? ""}
                  onChange={(event) =>
                    setQuestion({
                      ...question,
                      sectionId: event.target.value || null,
                    })
                  }
                >
                  <option value="">Без темы</option>
                  {sections.map((section) => (
                    <option key={section.id} value={section.id}>
                      {section.position}. {section.title}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Текст вопроса
                <textarea
                  required
                  value={question.text}
                  onChange={(event) =>
                    setQuestion({ ...question, text: event.target.value })
                  }
                />
              </label>
              <fieldset className="answer-editor">
                <legend>Варианты ответа</legend>
                {question.options.map((option, index) => (
                  <div key={index}>
                    <input
                      type="radio"
                      name="correct-option"
                      checked={question.correctOption === index + 1}
                      onChange={() =>
                        setQuestion({
                          ...question,
                          correctOption: index + 1,
                        })
                      }
                      aria-label={`Правильный ответ ${index + 1}`}
                    />
                    <input
                      required
                      value={option}
                      onChange={(event) => {
                        const options = [...question.options];
                        options[index] = event.target.value;
                        setQuestion({ ...question, options });
                      }}
                      placeholder={`Вариант ${index + 1}`}
                    />
                    <button
                      type="button"
                      onClick={() => {
                        const options = question.options.filter(
                          (_, optionIndex) => optionIndex !== index,
                        );
                        setQuestion({
                          ...question,
                          options,
                          correctOption: Math.min(
                            question.correctOption,
                            options.length,
                          ),
                        });
                      }}
                      disabled={question.options.length <= 2}
                      aria-label={`Удалить вариант ${index + 1}`}
                    >
                      <Trash2 />
                    </button>
                  </div>
                ))}
                {question.options.length < 10 && (
                  <button
                    type="button"
                    className="add-option"
                    onClick={() =>
                      setQuestion({
                        ...question,
                        options: [...question.options, ""],
                      })
                    }
                  >
                    <Plus /> Добавить вариант
                  </button>
                )}
              </fieldset>
              <button className="create-test submit" disabled={busy}>
                {busy ? "Сохраняю…" : "Сохранить вопрос"}
              </button>
            </form>
          </div>
        )}
      </aside>
    </div>
  );
}

function UserDrawer({
  user,
  links,
  onClose,
}: {
  user: ApiUser;
  links: ApiLink[];
  onClose: () => void;
}) {
  const related = links.find(
    (link) => link.owner.id === user.id || link.counterpart?.id === user.id,
  );
  const counterpart = related
    ? related.owner.id === user.id
      ? related.counterpart
      : related.owner
    : null;
  return (
    <div className="drawer-backdrop" onMouseDown={onClose}>
      <aside
        className="drawer"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <button className="drawer-close" onClick={onClose} aria-label="Закрыть">
          <X />
        </button>
        <div className="drawer-profile">
          <Avatar user={user} large />
          <h2>{user.name}</h2>
          <RoleBadge role={user.role} />
        </div>
        <div className="profile-fields">
          <Info icon={Mail} label="Email" value={user.email} />
          <Info icon={CalendarDays} label="Возраст" value={`${user.age} лет`} />
          <Info
            icon={CircleUserRound}
            label="Регистрация"
            value={formatDate(user.createdAt)}
          />
          <Info
            icon={Link2}
            label="Связанный аккаунт"
            value={counterpart?.name ?? "Нет активной связки"}
          />
        </div>
        <div className="drawer-note">
          <ShieldCheck />
          <p>
            <strong>Реальные данные</strong>
            <span>
              Информация загружена из PostgreSQL через защищённый admin API.
            </span>
          </p>
        </div>
      </aside>
    </div>
  );
}

function Stat({
  icon: Icon,
  tone,
  value,
  label,
  note,
  loading,
}: {
  icon: typeof Users;
  tone: string;
  value: number;
  label: string;
  note: string;
  loading: boolean;
}) {
  return (
    <article className="stat-card">
      <span className={`stat-icon ${tone}`}>
        <Icon />
      </span>
      <div>
        <strong>{loading ? "—" : value}</strong>
        <p>{label}</p>
        <small>{note}</small>
      </div>
    </article>
  );
}
function Avatar({
  user,
  large = false,
}: {
  user: { name: string; avatarIndex: number };
  large?: boolean;
}) {
  return (
    <span className={`avatar ${large ? "large" : ""}`}>
      <Image
        src={avatar(user.avatarIndex)}
        alt={user.name}
        width={large ? 80 : 44}
        height={large ? 80 : 44}
        unoptimized
      />
    </span>
  );
}
function UserIdentity({ user }: { user: ApiUser }) {
  return (
    <span className="user-identity">
      <Avatar user={user} />
      <span>
        <strong>{user.name}</strong>
        <small>{user.email}</small>
      </span>
    </span>
  );
}
function RoleBadge({ role }: { role: Role }) {
  return (
    <span className={`role-badge ${role.toLowerCase()}`}>
      {roleLabels[role]}
    </span>
  );
}
function Person({ person }: { person: ApiLink["owner"] }) {
  return (
    <div className="person">
      <Avatar user={person} />
      <div>
        <strong>{person.name}</strong>
        <span>{person.email}</span>
      </div>
    </div>
  );
}
function Info({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof Mail;
  label: string;
  value: string;
}) {
  return (
    <div className="info-row">
      <span>
        <Icon />
      </span>
      <div>
        <small>{label}</small>
        <strong>{value}</strong>
      </div>
    </div>
  );
}
function Empty({ text }: { text: string }) {
  return (
    <div className="empty">
      <Search />
      <p>{text}</p>
    </div>
  );
}
function LoadingRows() {
  return (
    <div className="loading-rows">
      <i />
      <i />
      <i />
    </div>
  );
}
