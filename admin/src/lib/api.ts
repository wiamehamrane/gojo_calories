import { API_URL } from "./types";

const TOKEN_KEY = "gojo_admin_token";
const ROLE_KEY = "gojo_admin_role";

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function getRole(): "admin" | "influencer" | null {
  if (typeof window === "undefined") return null;
  const role = localStorage.getItem(ROLE_KEY);
  if (role === "admin" || role === "influencer") return role;
  return null;
}

export function setToken(token: string, role?: string) {
  localStorage.setItem(TOKEN_KEY, token);
  if (role) localStorage.setItem(ROLE_KEY, role);
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ROLE_KEY);
}

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({ detail: "Request failed" }));
    throw new ApiError(body.detail || "Request failed", res.status);
  }

  if (res.status === 204) return {} as T;
  return res.json();
}

export async function login(email: string, password: string) {
  const data = await apiFetch<{ access_token: string; role?: string }>(
    "/admin/auth/login",
    {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }
  );
  setToken(data.access_token, data.role || "admin");
  return data;
}

export function logout() {
  clearToken();
  window.location.href = "/login";
}
